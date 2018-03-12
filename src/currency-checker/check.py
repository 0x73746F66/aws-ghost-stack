#!/usr/bin/env python
import ConfigParser, os, urllib, json, sys, requests, pytz, subprocess, ast
from datetime import datetime
from time import time

headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}

config = ConfigParser.RawConfigParser()
configFilePath = r'./wallet.cfg'
config.read(configFilePath)

DATA = {'pools': {}, 'summary': {}}
currency = config.get('other', 'currency')

net_position = 0
net_position_unconfirmed = 0

for COIN in sys.argv[1:]:
    coin_code = config.get(COIN, 'coin_code')
    DATA[COIN] = {}

    url1 = "%s/ticker/%s?convert=%s" % (config.get('other', 'rate_base_url'), COIN, currency)

    response1 = urllib.urlopen(url1)
    conversion_data = None
    for data in json.loads(response1.read()):
        if data != 'error' and data['id'] == COIN:
            conversion_data = data

    balance = 0
    DATA[COIN]['wallet_addr'] = []
    for wallet in ast.literal_eval(config.get(COIN, "wallet")):
        url2 = "%s/%s" % (config.get(COIN, 'explorer_base_url'), wallet)

        response2 = requests.get(url2, headers=headers)
        wallet_data = json.loads(response2.content)
        if 'error' in wallet_data:
            print "%s %s" % (wallet, wallet_data['error'])
            continue

        if COIN == 'zcash' or COIN == 'raven':
            balance += float(wallet_data['balance'])
            DATA[COIN]['wallet_addr'].append(wallet_data)
        else:
            balance += float(wallet_data['data']['balance'])
            DATA[COIN]['wallet_addr'].append(wallet_data['data'])

    DATA[COIN]['date'] = str(datetime.now(pytz.utc))
    DATA[COIN]['coin_text'] = "%s (%s)" % (COIN, coin_code)
    DATA[COIN]['coin'] = COIN
    DATA[COIN]['coin_code'] = coin_code
    DATA[COIN]['exchange_currency'] = currency
    DATA[COIN]['wallet_balance_text'] = "%0.8f %s" % (balance, coin_code)
    DATA[COIN]['wallet_balance'] = balance
    DATA['summary']["Wallet %s" % coin_code] = "%0.8f %s" % (balance, coin_code)

    url3 = "%s" % config.get(COIN, 'pools_base_url')
    response3 = requests.get(url3, headers=headers)
    pool_data = json.loads(response3.content)

    if 'getuserbalance' in pool_data:
        DATA['pools'][pool_coin] = pool_data['getuserbalance']
        pool_balance = pool_data['getuserbalance']['data']
        net_coin = 0
        net_coin_unconfirmed = 0
        if float(pool_balance['unconfirmed']) > 0:
            net_coin_unconfirmed += float(pool_balance['unconfirmed'])
        if float(pool_balance['confirmed']) > 0:
            net_coin += float(pool_balance['confirmed'])
        DATA['summary']["%s POOL NET" % coin_code] = "%0.8f %s" % (net_coin, coin_code)
        DATA['summary']["%s POOL Unconfirmed" % coin_code] = "%0.8f %s" % (net_coin_unconfirmed, coin_code)
        coin_total_all = net_coin_unconfirmed + net_coin + DATA[COIN]['wallet_balance']
        DATA['summary']["%s Total" % coin_code] = "%0.8f %s" % (coin_total_all, coin_code)

    if not conversion_data:
        continue

    rate = float(conversion_data['price_aud'])
    DATA[COIN]['exchange_rate'] = rate
    DATA[COIN]['exchange_rate_data'] = conversion_data
    DATA[COIN]['exchange_rate_text'] = "1 %s = %0.2f %s" % (coin_code, rate, currency)
    DATA[COIN]['wallet_value'] = balance * rate
    DATA['summary']["Wallet %s" % coin_code] = "%0.2f (%0.8f %s @ %0.2f %s)" % (balance * rate, balance, coin_code, rate, currency)

    if 'getuserallbalances' in pool_data:
        for pool_balance in pool_data['getuserallbalances']['data']:
            pool_coin = pool_balance['coin']
            DATA['pools'][pool_coin] = pool_balance
            net_coin = 0
            net_coin_unconfirmed = 0

            if float(pool_balance['unconfirmed']) > 0:
                net_coin_unconfirmed += float(pool_balance['unconfirmed'])
            if float(pool_balance['confirmed']) > 0:
                net_coin += float(pool_balance['confirmed'])
            if float(pool_balance['ae_confirmed']) > 0:
                net_coin += float(pool_balance['ae_confirmed'])
            if float(pool_balance['ae_unconfirmed']) > 0:
                net_coin_unconfirmed += float(pool_balance['ae_unconfirmed'])
            if float(pool_balance['exchange']) > 0:
                net_coin += float(pool_balance['exchange'])

            coin_conversion_data = None
            coin_rate = None
            if net_coin > 0 or net_coin_unconfirmed > 0:
                coin_conversion_url = "%s/ticker/%s?convert=%s" % (config.get('other', 'rate_base_url'), pool_coin, currency)
                coin_conversion_response = urllib.urlopen(coin_conversion_url)
                for data in json.loads(coin_conversion_response.read()):
                    if data == 'error':
                        coin_conversion_url = "%s/ticker/%s?convert=%s" % (config.get('other', 'rate_base_url'), pool_coin.split('-').pop(0), currency)
                        coin_conversion_response = urllib.urlopen(coin_conversion_url)

                        for data in json.loads(coin_conversion_response.read()):
                            if data != 'error' and data['id'] == pool_coin:
                                coin_conversion_data = data
                    else:
                        coin_conversion_data = data
            if coin_conversion_data:
                coin_rate = float(coin_conversion_data['price_aud'])
                DATA['pools'][pool_coin]['exchange_rate_text'] = "1 %s = %0.2f %s" % (coin_conversion_data['symbol'], coin_rate, currency)

            if coin_conversion_data and net_coin > 0 and coin_rate:
                net_value = (coin_rate * net_coin)
                net_position += net_value
                DATA['pools'][pool_coin][currency] = net_value

            if coin_conversion_data and net_coin_unconfirmed > 0 and coin_rate:
                net_value = (coin_rate * net_coin)
                net_position_unconfirmed += net_value
                DATA['pools'][pool_coin]["%s_unconfirmed" % currency] = net_value

if net_position > 0:
    DATA['summary']["POOL NET"] = "%0.2f %s" % (net_position, currency)
if net_position_unconfirmed > 0:
    DATA['summary']["POOL Unconfirmed"] = "%0.2f %s" % (net_position_unconfirmed, currency)

total_value = 0
for k, c in enumerate(DATA):
    try:
        if DATA[c]['wallet_value']:
            total_value += DATA[c]['wallet_value']
    except KeyError:
        pass

DATA['summary']["[Grand Total]"] = "%0.2f %s" % (net_position + total_value, currency)

for COIN in sys.argv[1:]:
    try:
        if float(DATA['pools'][COIN]['confirmed']) > 0 and float(DATA[COIN]['wallet_balance']) > 0:
            coin_code = DATA[COIN]['coin_code']
            rate = DATA[COIN]['exchange_rate']
            balance = DATA['pools'][COIN]['confirmed'] + DATA[COIN]['wallet_balance']
            DATA['summary']["Total %s" % coin_code] = "%0.2f %s (%0.8f)" % (balance * rate, currency, balance)
    except KeyError:
        pass

bucket = config.get('other', 's3_bucket')
profile = config.get('other', 'aws_profile')
aws = config.get('other', 'aws_bin')
fp = "%d.json" % int(time())
with open(fp, 'w') as outfile:
    json.dump(DATA, outfile, ensure_ascii=False, indent=2, sort_keys=True)

status = None
try:
    upload = subprocess.Popen("%s s3 cp --profile %s %s s3://%s/%s > /dev/null" % (aws, profile, fp, bucket, fp), shell=True, stderr=subprocess.PIPE, cwd=os.path.dirname(os.path.realpath(__file__)))
    err = upload.stderr.read()
    if err:
        print "err [%s]" % err
        sys.exit(1)
    status = subprocess.Popen("%s s3 presign --profile %s s3://%s/%s" % (aws, profile, bucket, fp), shell=True, stdout=subprocess.PIPE, cwd=os.path.dirname(os.path.realpath(__file__)))
except OSError as e:
    print e
    sys.exit(1)

if status:
    print "%s" % status.stdout.read()

for k, v in enumerate(sorted(DATA['summary'])):
    print "%s\n%s\n" % (v, DATA['summary'][v])

