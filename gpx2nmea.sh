#!/usr/bin/env bash

set -ex
gpsbabel -i gpx -f special_delivery.gpx -o nmea,gpgga=1,gpgsa=1,gprmc=1,date=20201223 -F SpecialDelivery.nmea
