#!/usr/bin/env python
import os, urllib, json, sys, requests

url = "https://api.coinmarketcap.com/v1/ticker/"
print "[URL] %s" % url
response1 = urllib.urlopen(url)
currencies = []

for data in json.loads(response1.read()):
    if data['id']:
        currencies.append(data['id'])

currencies.sort()
for x in sorted(currencies):
    print x


with open("coinmarketcap_currencies.json", 'w') as outfile:
    json.dump(currencies, outfile, indent=2, sort_keys=True)