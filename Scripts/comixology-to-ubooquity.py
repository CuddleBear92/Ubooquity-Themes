#!/usr/bin/env python

import argparse
import collections
import functools
import json
import os
import random
import re
import time
import types
import urllib.parse
from typing import List, Dict, Union

import bs4
import requests

USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3835.0 Safari/537.36'
PUBLISHER_LIST_URL = 'https://www.comixology.com/browse-publisher'
FOLDER_INFO_HTML_TEMPLATE = '''
<link rel="stylesheet" type="text/css" href="[[FOLDER]]/folder.css">
{header_div_html}
{imprint_navigation_html}
<script>document.getElementById("group").classList.add("publisherPage");</script>
'''
IMPRINT_NAVIGATION_DEFAULT_URL = '/ubooquity/comics/1/'
FOLDER_CSS_TEMPLATE = '''
#group{{
    background-color: {background_color} !important;
    color: {text_color} !important;
    padding-top: 0;
}}

.label{{
    color: {text_color} !important;
}}'''
HEADER_DIV_HTML = '<div align="center"><img src="[[FOLDER]]/header.jpg" width="100%"></div>'

COLOR_REGEX = re.compile(r'color:\s*(.+);', re.IGNORECASE)
TITLE_DATE_REGEX = re.compile(r'\((\d{4})-?(\d{4})?\)', re.IGNORECASE)
WHITESPACE_REGEX = re.compile(r'\s\s+')
# https://stackoverflow.com/questions/1976007/what-characters-are-forbidden-in-windows-and-linux-directory-names
UNSAFE_CHARACTERS = '/<>:"/\\|?*'
PublisherListing = collections.namedtuple('PublisherListing', ['title', 'url', 'logo_url'])
Publisher = collections.namedtuple('Publisher', ['imprint_nav', 'header_url', 'background_color', 'text_color'])
SeriesListing = collections.namedtuple('SeriesListing', ['title', 'url', 'logo_url'])
Series = collections.namedtuple('Series', ['description', 'year'])

Number = Union[float, int]


def make_soup(response) -> bs4.BeautifulSoup:
    return bs4.BeautifulSoup(response.text, 'html5lib')


def get_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument('--user-agent', '-u', default=USER_AGENT)
    parser.add_argument('--destination', '-d', default=os.getcwd())
    parser.add_argument('--scrape-series', '-s', action='store_true')
    parser.add_argument('--request-attempts', '-a', default=3)
    parser.add_argument('--delay-range', '-D', nargs=2, type=float, default=[1, 3])
    parser.add_argument('--timeout', '-t', type=float, default=60)
    parser.add_argument('--skip-existing-publisher', '-sp', action='store_true')
    parser.add_argument('--skip-existing-series', '-ss', action='store_true')
    return parser


def scrape_publisher_list_page(soup: bs4.BeautifulSoup) -> List[PublisherListing]:
    publishers = []
    for item in soup.select('.publisherList .content-item'):
        content_img_link = item.select_one('.content-img-link')
        content_img = content_img_link.select_one('.content-img')
        publisher = PublisherListing(normalize_whitespace(content_img['title']), content_img_link['href'], content_img['src'])
        publishers.append(publisher)

    return publishers


def scrape_publisher_list(session: requests.Session) -> List[PublisherListing]:
    publishers = []
    page_url = PUBLISHER_LIST_URL
    while True:
        response = session.get(page_url)
        soup = make_soup(response)
        publishers.extend(scrape_publisher_list_page(soup))

        next_page = soup.select_one('.publisherList .next-page')
        if not next_page:
            break
        page_url = urllib.parse.urljoin(response.url, next_page['href'])

    return publishers


def get_file(session: requests.Session, url: str, **requests_kwargs) -> bytes:
    response = session.get(url, **requests_kwargs)
    return response.content


def parse_style_attribute(css: str) -> Dict[str, str]:
    instructions = {}

    tokens = css.split(';')
    for token in tokens:
        token = token.strip()
        if not token:
            continue

        key, value = token.split(':', 1)
        instructions[key.strip()] = value.strip()

    return instructions


def scrape_publisher(session: requests.Session, url: str) -> Publisher:
    response = session.get(url)
    soup = make_soup(response)
    publisher_page_outer = soup.select_one('.publisherPageOutter')
    publisher_page_outer_style = parse_style_attribute(publisher_page_outer['style'])
    background_color = publisher_page_outer_style['background-color']
    style = soup.select_one('.content_body style').string

    matches = COLOR_REGEX.findall(style)
    if len(matches) > 1:
        print('Warning, found more than one potential text color: {!r}'.format(matches))
    text_color = matches[0]

    publisher_page = publisher_page_outer.select_one('.publisherPage')
    publisher_page_style = parse_style_attribute(publisher_page['style'])
    header_url = publisher_page_style['background-image'].split('url(', 1)[1].rsplit(')', 1)[0]
    imprint_nav = publisher_page.select_one('.imprintNav')
    return Publisher(imprint_nav, header_url, background_color, text_color)


def ubooquityfy_imprint_navigation(soup: bs4.BeautifulSoup) -> bs4.BeautifulSoup:
    for a in soup.select('a'):
        a['href'] = IMPRINT_NAVIGATION_DEFAULT_URL

    return soup


def scrape_publisher_series_list_page(soup: bs4.BeautifulSoup) -> List[SeriesListing]:
    series = []
    for item in soup.select('.seriesList .content-item'):
        content_img_link = item.select_one('.content-img-link')
        content_img = content_img_link.select_one('.content-img')
        publisher = SeriesListing(content_img['title'], content_img_link['href'], content_img['src'])
        series.append(publisher)

    return series


def scrape_publisher_series_list(session: requests.Session, url: str) -> List[SeriesListing]:
    series = []

    page_url = url
    while True:
        response = session.get(page_url)
        soup = make_soup(response)
        series.extend(scrape_publisher_series_list_page(soup))

        next_page = soup.select_one('.seriesList .next-page')
        if not next_page:
            break

        page_url = urllib.parse.urljoin(response.url, next_page['href'])

    return series


def scrape_series(session: requests.Session, url: str) -> Series:
    response = session.get(url)
    soup = make_soup(response)

    # name = soup.select_one('[itemprop="name"]').get_text()
    description = soup.select_one('[itemprop="description"]').get_text()

    first_item_href = soup.select_one('.item-list .content-item a')['href']
    first_item_url = urllib.parse.urljoin(response.url, first_item_href)
    response = session.get(first_item_url)
    soup = make_soup(response)

    release_years = []
    for subtitle in soup.select('.subtitle'):
        if subtitle.string.endswith(' Release Date'):
            about_text = subtitle.find_next_sibling(class_='aboutText')
            release_years.append(int(about_text.string.rsplit(None, 1)[1]))

    return Series(description=description, year=sorted(release_years)[0])


def normalize_whitespace(string: str) -> str:
    return WHITESPACE_REGEX.sub(' ', string).strip()


def get_series_metadata(series_listing: SeriesListing, series: Series, publisher_listing: PublisherListing) -> Dict:
    match = TITLE_DATE_REGEX.search(series_listing.title)
    year_candidates = []

    if match:
        title = TITLE_DATE_REGEX.sub('', series_listing.title)
        year_candidates.append(int(match.group(1)))
    else:
        title = series_listing.title

    title = normalize_whitespace(title)
    year_candidates.append(series.year)

    # Use earliest discovered year
    year = sorted(year_candidates)[0]
    return {
        'description': series.description,
        'name': title,
        'year': str(year),
        'publisher': publisher_listing.title,
        'type': 'comicSeries'
    }


def get_safe_file_name(file_name: str, replacement: str = '') -> str:
    return ''.join(character if character not in UNSAFE_CHARACTERS else replacement for character in file_name)


def get_random_delay(lower: Number, upper: Number) -> Number:
    range_ = upper - lower
    mean = (upper + lower) / 2
    delay = random.normalvariate(mean, range_ / 4)
    return max(lower, min(upper, delay))


def get_adjust_delay(delay: Number, last_request_time: Number) -> Number:
    return max(0, delay - (time.time() - last_request_time))


def make_requests_session(arguments: argparse.Namespace) -> requests.Session:
    session = requests.session()
    session._last_request_times = collections.defaultdict(float)

    original_request = session.request

    def request(self, method, url, **kwargs):
        attempts = max(1, arguments.request_attempts)
        for attempt in range(1, attempts):
            netloc = urllib.parse.urlsplit(url).netloc

            raw_delay = get_random_delay(*arguments.delay_range)
            delay = get_adjust_delay(raw_delay, self._last_request_times[netloc])
            if delay > 0:
                time.sleep(delay)

            self._last_request_times[netloc] = time.time()
            try:
                response = original_request(method, url, **kwargs)
            except requests.exceptions.ConnectionError:
                if attempt >= attempts:
                    raise

                continue
            return response

    # https://stackoverflow.com/questions/47113376/python-3-x-requests-redirect-with-unicode-character
    original_get_redirect_target = session.get_redirect_target

    def get_redirect_target(response):
        try:
            return original_get_redirect_target(response)
        except UnicodeDecodeError:
            return response.headers['Location']

    session.get_redirect_target = get_redirect_target

    session.request = types.MethodType(request, session)
    session.request = functools.partial(session.request, timeout=arguments.timeout)
    session.headers['User-Agent'] = arguments.user_agent
    return session


def main(arguments: argparse.Namespace):
    session = make_requests_session(arguments)
    print('Scraping publishers...')
    publishers = scrape_publisher_list(session)
    publishers_count = len(publishers)
    for publisher_index, publisher_listing in enumerate(publishers, start=1):
        print('+ ({}/{}) Scraping publisher: {!r}...'.format(publisher_index, publishers_count, publisher_listing.title))
        comics_destination = os.path.join(arguments.destination, 'comics', get_safe_file_name(publisher_listing.title))
        if arguments.skip_existing_publisher and os.path.exists(comics_destination):
            print(' - Skipping existing publisher: {!r}'.format(comics_destination))
            continue

        theme_destination = os.path.join(arguments.destination, 'themes')
        os.makedirs(comics_destination, exist_ok=True)
        os.makedirs(theme_destination, exist_ok=True)

        print(' - Downloading logo from: {!r}'.format(publisher_listing.logo_url))
        logo_data = get_file(session, publisher_listing.logo_url)
        comics_logo_path = os.path.join(comics_destination, 'folder.jpg')
        theme_logo_path = os.path.join(theme_destination, '{}.jpg'.format(get_safe_file_name(publisher_listing.title)))
        for path in comics_logo_path, theme_logo_path:
            print(' - Saving logo to: {!r}...'.format(path))
            with open(path, 'wb') as file:
                file.write(logo_data)

        print(' - Scraping publisher page: {!r}...'.format(publisher_listing.url))
        publisher = scrape_publisher(session, publisher_listing.url)

        if publisher.header_url:
            print(' - Downloading header from: {!r}...'.format(publisher.header_url))
            header_data = get_file(session, publisher.header_url)
            header_path = os.path.join(comics_destination, 'header.jpg')
            print(' - Saving header to: {!r}...'.format(header_path))
            with open(header_path, 'wb') as file:
                file.write(header_data)
            header_div_html = HEADER_DIV_HTML
        else:
            header_div_html = ''

        if publisher.imprint_nav:
            imprint_navigation_html = ubooquityfy_imprint_navigation(publisher.imprint_nav).prettify()
        else:
            imprint_navigation_html = ''

        folder_info_html = FOLDER_INFO_HTML_TEMPLATE.format(imprint_navigation_html=imprint_navigation_html, header_div_html=header_div_html).strip()
        folder_info_html_path = os.path.join(comics_destination, 'folder-info.html')

        print(' - Writing folder-info.html to: {!r}...'.format(folder_info_html_path))
        with open(folder_info_html_path, 'w', encoding='UTF-8') as file:
            file.write(folder_info_html)

        folder_css = FOLDER_CSS_TEMPLATE.format(background_color=publisher.background_color, text_color=publisher.text_color)
        folder_css_path = os.path.join(comics_destination, 'folder.css')
        print(' - Writing folder.css to: {!r}'.format(folder_css_path))
        with open(folder_css_path, 'w', encoding='UTF-8') as file:
            file.write(folder_css)

        if arguments.scrape_series:
            print(' - Scraping series...')
            series = scrape_publisher_series_list(session, publisher_listing.url)
            series_count = len(series)
            for series_index, series_listing in enumerate(series, start=1):
                print(' + ({}/{}) Scraping series: {!r}...'.format(series_index, series_count, series_listing.title))
                series = scrape_series(session, series_listing.url)

                # Use series metadata from now on because we have processed it slightly
                metadata = get_series_metadata(series_listing, series, publisher_listing)

                series_destination = os.path.join(comics_destination, get_safe_file_name('{} ({})'.format(metadata['name'], metadata['year'])))
                if arguments.skip_existing_series and os.path.exists(series_destination):
                    print('  - Skipping existing series: {!r}'.format(series_destination))
                    continue

                os.makedirs(series_destination, exist_ok=True)

                print('  - Downloading logo from: {!r}'.format(series_listing.logo_url))
                series_logo_data = get_file(session, series_listing.logo_url)
                series_logo_path = os.path.join(series_destination, 'folder.jpg')
                print('  - Saving logo to: {!r}...'.format(series_logo_path))
                with open(series_logo_path, 'wb') as file:
                    file.write(series_logo_data)

                metadata_path = os.path.join(series_destination, 'series.json')
                print('  - Saving series metadata to: {!r}'.format(metadata_path))
                with open(metadata_path, 'w', encoding='UTF-8') as file:
                    json.dump({'metadata': [metadata]}, file)


if __name__ == '__main__':
    parser = get_argument_parser()
    arguments = parser.parse_args()
    parser.exit(main(arguments))
