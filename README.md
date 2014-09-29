# OSXWiki2CSV.sh
============
For what ?
-------------

This tool is designed to export OSX Server (10.6) wiki/blog pages to CSV. 

This tool can also export all the data (images, html files, etc.).

This tool must be run as root: use 'sudo'.


Install & Usage
-------------


To install, from your terminal:

	git clone https://github.com/yvangodard/OSX-Wiki-2-CSV.git ; 
	sudo chmod -R 750 OSX-Wiki-2-CSV

And prints help:

    cd OSX-Wiki-2-CSV
    ./OSXWiki2CSV.sh help
    
##### Synopsis:

    ./OSXWiki2CSV.sh [-h]
                 -p <url prefix>
                 -b <export path>
                 [-f <path of collaboration files>]
                 [-D <backup data>]
                 [-d <number of daily exports>] [-w <number of weekly exports>]
                 [-e <email report option>] [-E <email address>] [-j <log file>]


##### Mandatory options:

- `-p <url prefix>`: the prefix to append to generated links, without spaces (i.e.: `http://my-server.example.com/groups/wiki/`)
- `-b <export path>`: the full path of your backup directory (i.e.: `/Users/Shared/backupWikiServer`)

##### Optional options:
	
- `-f <path of collaboration files>`: the full path of your OS X Server collaboration files, default `/Library/Collaboration`
- `-D <backup data>`: type `-D yes` if you want to include all the data in your export, not only CSV exports or `-D no` if not. Default: `-D no`.
- `-d <number of daily exports>`: number of daily exports to keep (default: 6).
- `-w <number of weekly exports>`: number of weekly exports to keep (default: 4).
- `-e <email report option>`: settings for sending a report by email, must be `onerror`, `forcemail` or `nomail`, default: `nomail`.
- `-E <email address>`: email address to send the report, must be filled if `-e forcemail` or `-e onerror` options is used.
- `-j <log file>`: enables logging instead of standard output. Specify an argument for the full path to the log file (i.e.: `/var/log/OSXWiki2CSV.log`) or use `default` (`/var/log/OSXWiki2CSV.log`).

Bug report
-------------

If you want to to send me a bug : [open an issue ticket](https://github.com/ygodard/OSX-Wiki-2-CSV/issues).

Thanks to
-------------
This tool is based on two scripts.

One by Jon Brown:
- http://www.jonbrown.org/export-osx-wiki-server-to-csv
- https://github.com/jonbrown21/OSX-Wiki-2-CSV

The other by Meitar Moscovitz:
- http://maymay.net/blog/2008/09/22/extract-list-of-all-apple-wikiserver-wiki-titles-into-csv-format
- https://github.com/meitar/wikipages2csv/
