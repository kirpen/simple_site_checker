# Pokupon status checker

## Preparation env

`bundler install`

## Run smtp chatcher

`mailcatcher -f`

open in a browser to view sent emails, default: http://127.0.0.1:1080/

## Start as daemon

`ruby site_checker.rb start`

## Stop daemon

`ruby site_checker.rb stop`

## Settings

To test the fall of services, you can use additional URLs on line 14
And also enable the sending of a letter to return the status of 200 in case of restoration of the site on line 15