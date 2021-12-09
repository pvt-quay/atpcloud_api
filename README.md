
## What this is

**DESCRIPTION:** A command line interface script to utilize the Juniper Networks' Cloud ATP API. Written in Ruby utilizing only the Ruby stdlib. Yes there are programming languages other than Python.

As of November 2021, the Juniper Network ATP Cloud feed API is documented here:

https://www.juniper.net/documentation/en_US/release-independent/sky-atp/information-products/topic-collections/sky-atp-open-apis.html#operation--v1-skyatp-submit-sample-post

Included are:
 - atp.rb - the main program
 - lib/opts/opts.rb - CLI options parser
 - lib/http/http.rb - handles HTTP functions
 - example_data/ - directory with various example data files
 - this README.md file

**NOTE:** this utility does not yet implement the "submit sample" API.

## Author(s)
Daniel McNulty, Lead Security Specialist at Juniper Networks

## License
BSD 3-clause

## Copyright
Copyright (c) 2021, Daniel McNulty. All rights reserved.

# Usage

## Obtain an authorization token

Before using this tool an authentication token must be obtained from Juniper's ATP Cloud. Simply log into the web interface, go to "Administration - Application Tokens" and create a token. When created cut and paste the token to a file. You will use this token to authorize access to your ATP Cloud security intelligence feeds and lists.

**CAUTION:** Keep this token secure! Anyone with access to the token has access to your ATP Cloud data.

## Using the token

The "-t" option specifies the token to use. The "-t" parameter can accept the token either as a string directly on the CLI:

    -t areallyreallylonglineofrandomalphanumericdata

or via command substitution:

    -t $(cat ./auth_token)

or as a filename, where the file contains the token on a single line. In most situations it is more convenient simply to input the token as a file:

    -t ./auth_token

## Command Line Options

    Description: Interfaces to ATP Cloud API
    Usage: ./atp.rb [options]
        -a, --action ACTION              Action to perform - ping, get, add, delete, lookup, submit
        -d, --debug                      Turn on debug output - goes to STDERR
        -D, --domain [DOMAIN|FILE]       Domain or file with domains - used with get, add or delete actions
        -i, --ip [IP|FILE]               IP address or file with IPs - used with get, add or delete actions
        -I, --ih                         Get the Infected Hosts feed
        -k, --no_ssl_verify              Turn off ssl certificate verification - INSECURE!
        -l, --list LIST                  List to utilize - must be allowlist or blocklist, used with get,
                                         add or delete actions
        -p, --ping                       Ping the API - If alive, the API should return "I am a potato."
                                         Alias for "-a ping"
        -t, --token STRING|FILE          Authorization token
        -u, --url [URL|FILE]             URL or file with URLs - used with get, add or delete actions
        -v, --version                    Shows the version
        -h, -?, --help                   Prints this help



# Examples

**NOTE:** For human readability the examples below display output as multi-line json, but in practice atp.rb outputs single-line json.

## List manipulation
ATP Cloud supports two types of custom feeds; an allowlist and a blocklist. When implemented in an ATP policy on a Juniper Networks SRX firewall, the allowlist is intended to permit anything in the list. Similarly, the blocklist blocks anything in the list. Documentation is located here: 

https://www.juniper.net/documentation/us/en/software/sky-atp/sky-atp/topics/concept/sky-atp-whitelist-blacklist-overview.html

Allowlists and blocklists can contain IP, URL and domain entities. The following examples use a "domain" entity type which uses the "-D" or "--domain" entity parameters. All lists are accessible and manipulated the same way by changing the CLI entity parameter to the appropriate entity type. For example, URL lists use "-u" or "--url," and IP lists use "-i" or "--ip."

Combine the entity type parameter with an action parameter to get the contents of a list, or add or delete items from a list.

## Retrieving a list

When retrieving the contents of a list the entity type parameter takes no argument:

    $ ./atp.rb -a get -l blocklist -D -t auth_token
    {
      "data": {
        "count": 2,
        "servers": [
          "another.com",
          "some.com"
        ]
      },
      "request_id": "c0588ca9-c79d-4997-81bc-8351a8903c0b"
    }

## Add single entities

When adding or deleting entities from a list, the entity type parameter takes an argument. The argument can be single entity or a file containing multiple entities (one per line):

    $ ./atp.rb -a add -l blocklist -D yetanotherdomain.com -t auth_token
    {
      "data": {},
      "request_id": "7a42437e-0c68-448b-9bb2-5d7a90a93f56"
    }

Result:

    $ ./atp.rb -a get -l blocklist -D -t auth_token
    {
      "data": {
        "count": 3,
        "servers": [
          "another.com",
          "some.com",
          "yetanotherdomain.com"
        ]
      },
      "request_id": "50f7d115-8c28-4f77-bb6a-2f560283f402"
    }

## Delete single entities

    $ ./atp.rb -a delete -l blocklist -D another.com -t auth_token
    {
      "data": {},
      "request_id": "45baa298-a3e5-423b-a715-ea933fcc4b8a"
    }

Result:

    $ ./atp.rb -a get -l blocklist -D -t auth_token
    {
      "data": {
        "count": 2,
        "servers": [
          "some.com",
          "yetanotherdomain.com"
        ]
      },
      "request_id": "334843a9-bd7d-40cf-a271-bb9a75189436"
    }

## Delete multiple entities

Contents of file

    $ cat example_data/domain_blocklist
    some.com
    yetanotherdomain.com

Command using an entity list file:

    $ ./atp.rb -a delete -l blocklist -D example_data/domain_blocklist -t auth_token
    {
      "request_id": "065d6461-4ff0-4adf-9844-c859ae3c3fc3"
    }

Result:

    $ ./atp.rb -a get -l blocklist -D -t auth_token
    {
      "data": {},
      "request_id": "0e191a95-6e32-44b1-b917-407f55a6b215"
    }

## Retrieve the "infected hosts" feed

    $ ./atp.rb -I -t auth_token
    {
      "data": {
        "count": 1,
        "ip": [
          {
            "10.0.3.171": 10
          }
        ]
      },
      "request_id": "f1f21751-022c-4161-bc68-314248fadb9a"
    }

## Lookup a file hash

When ATP Cloud receives a file for analysis it will keep a SHA256 hash of that file in its database. When the analysis is complete the hash record is updated with metadata.

Note the different field contents for this benign file:

    $ ./atp.rb -H benign_hash -t auth_token
    {
      "category": "archive",
      "last_update": 1463200282,
      "scan_complete": true,
      "score": 0,
      "sha256": "516f3396086598142db5e242bc2c8f69f4f5058a637cd2f9bf5dcb4619869536",
      "size": 106335,
      "threat_level": "clean"
    }

And compare to a malicious file:

    $ ./atp.rb -H malicious_hash -t auth_token
    {
      "category": "executable",
      "last_update": 1633618827,
      "malware_info": {
        "family": "TROJAN_RANSOM",
        "mw_type": "Trojan"
      },
      "scan_complete": true,
      "score": 10,
      "sha256": "470dfc18e05c01ebd66fb8b320ff7e6e76d8017feb530fb23b981982c737b490",
      "size": 3723264,
      "threat_level": "high"
    }

## Show version information

"last_update" in seconds since the Epoch.

    $ ./atp.rb -v
    {
      "version": "0.0.1",
      "last_update": 1635708532
    }
