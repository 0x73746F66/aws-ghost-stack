import os
import requests
from pprint import pprint
from bs4 import BeautifulSoup
import boto3

TABLE_NAME = "lobbdawg_test"

conn = dynamodb2.connect_to_region(
    os.environ['AWS_REGION'],
    aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY'],
)
table = Table(
    '',
    connection=conn
)

DOMAIN = 'http://www.chanel.com'

def fetch(url):
    page = requests.get(url)
    return BeautifulSoup(page.text, 'lxml')

def get_links(soup, className):
    for productlines in soup.find_all(lambda tag: tag.has_attr('class') and className in tag['class']):
        tree = BeautifulSoup("<html>%s</html>" % productlines, 'lxml')
        for link in tree.find_all('a'):
            yield link.get('href')

def get_product_page_links(soup):
    all_links = soup.find_all('a', class_='no-select')
    for a in  all_links:
        str = "%s" % a
        if str.lower().find("view by categories") > -1:
            yield a['href']
            break
        elif str.lower().find("view by themes") > -1:
            yield a['href']
            break
    all_links = soup.find_all('a', class_='nav-link')
    for a in  all_links:
        if '#' is not a['href']:
            yield a['href']


def get_product_links(soup):
    all_links = soup.find_all('a', class_='product-link')
    for link in all_links:
        yield link['href']

dd = boto3.client('dynamodb')


# print "[GET] %s/en_AU/fashion.html#products" % DOMAIN
response1 = fetch("%s/en_AU/fashion.html#products" % DOMAIN)
for link in get_links(response1, "fs-navigation-secondary-menus--productlines"):
    # print "[GET] %s%s" % (DOMAIN, link)
    response2 = fetch("%s%s" % (DOMAIN, link))
    for plink in get_product_page_links(response2):
        response3 = fetch("%s%s" % (DOMAIN, plink))
        for product_link in get_product_links(response3):
            print "%s%s" % (DOMAIN, product_link)