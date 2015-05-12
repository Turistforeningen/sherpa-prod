#!/usr/bin/env python
from datetime import datetime, timedelta
import subprocess
import time
import os

from sh import git, tar, rm
import boto
import ftputil
from raven import Client

import settings

raven = Client(dsn=settings.raven_url)
print("\nInitiating backup at: %s" % datetime.now()) # Set datestamp in output (which is logged), might be useful

try:
    dateformat = '%Y%m%d'
    now = datetime.now()

    # Keep 30 days of daily backups and 1 year of monthly backups
    def clean_old_backups(buck, prefix, name):

        # Delete year-old backups
        date = (now - timedelta(days=365)).strftime(dateformat)
        key = boto.s3.key.Key(buck, name="%s%s-%s.tgz" % (prefix, name, date))
        if key.exists():
            key.delete()

        # Delete month-old backups, except for the first in the month
        then = now - timedelta(days=30)
        if then.day != 1:
            key = boto.s3.key.Key(buck, name="%s%s-%s.tgz" % (prefix, name, then.strftime(dateformat)))
            if key.exists():
                key.delete()

    sherpa_bucket = [b for b in settings.buckets if b['name'] == 'cdn.turistforeningen.no'][0]
    conn = boto.connect_s3(sherpa_bucket['creds']['access_key'], sherpa_bucket['creds']['secret_key'])
    buck = conn.get_bucket('cdn.turistforeningen.no')

    #
    # Sherpa-databasen
    #

    print("Dumping sherpa db to S3...")
    name = 'sherpa'
    path = 'backups/sherpa/'
    filename = '%s-%s.gz' % (name, now.strftime(dateformat))

    key = boto.s3.key.Key(buck, name="%s%s" % (path, filename))
    db = subprocess.check_output([
        '/usr/bin/pg_dump -Fc -U postgres -h %s -p %s sherpa | gzip' % \
            (os.environ.get('POSTGRES_PORT_5432_TCP_ADDR'), os.environ.get('POSTGRES_PORT_5432_TCP_PORT'))
    ], stdin=subprocess.PIPE, shell=True)
    key.set_contents_from_string(db)

    clean_old_backups(buck, path, name)

    #
    # Kodebasen
    #

    print("Cloning git codebase and sending to S3...")
    name = 'sherpa'
    path = 'backups/kodebase/'
    filename = '%s-%s.tgz' % (name, now.strftime(dateformat))

    git('clone', 'https://github.com/Turistforeningen/sherpa.git')
    tar('-czf', filename, 'sherpa')

    key = boto.s3.key.Key(buck, name="%s%s" % (path, filename))
    key.set_contents_from_filename(filename)

    rm('-r', 'sherpa/')
    rm(filename)
    clean_old_backups(buck, path, name)

    #
    # Now backup the ENTIRE S3 (including backup folder) to our local on-site FTP server
    #

    def iterate_dir(host, dir):
        names = []
        for name in host.listdir(dir):
            if(host.path.isdir('%s/%s' % (dir, name))):
                names.extend(iterate_dir(host, '%s/%s' % (dir, name)))
            else:
                names.append(('%s/%s' % (dir, name)))
        return names

    # Our Windows-based FTP server has case-insensitive file- and dirnames, so we'll
    # get some collisions. Minimize the risk for that by including the entire S3 path
    # in the filename - dirs sparated by '.', filename separated by '--'.
    # Note that if a dir in the path includes '--' in its name, which is unlikely but
    # possible, it might not be obvious which part is a dir and which is a filename.
    def flat_name(name):
        dirs = name.split('/')
        return '%s--%s' % ('.'.join(dirs[:-1]), dirs[-1])

    print("Cloning S3 (without versioning) to local FTP server...")
    FTP_PREFIX = '/backups/s3'

    for bucket in settings.buckets:
        print("  Bucket: %s" % bucket['name'])

        # Define the logic in a function to be able to retry on failure
        def attempt_ftp_clone():
            # First save a list of existing file versions on the FTP-server.
            with ftputil.FTPHost(*settings.ftp_args) as host:
                existing_names = iterate_dir(host, "%s/%s" % (FTP_PREFIX, bucket['name']))

            # Initiate the S3-connection
            conn = boto.connect_s3(bucket['creds']['access_key'], bucket['creds']['secret_key'])
            buck = conn.get_bucket(bucket['name'])

            """
            For now, save all normal keys, ignoring versioning. When IT gives us a larger disk,
            consider storing all versions as well (see vcs history for previous code).
            """
            for v in buck.list():
                # Skip folders
                if v.name.endswith('/'):
                    continue

                # Skip explicitly excluded paths
                exclude_match = False
                for exclude in bucket['excludes']:
                    if v.name.startswith(exclude):
                        print("  %s skipped (matches excluded path: %s)" % (v.name, exclude))
                        exclude_match = True
                if exclude_match:
                    continue

                ftp_path = '%s/%s/%s' % (FTP_PREFIX, bucket['name'], flat_name(v.name))

                if ftp_path in existing_names:
                    # Note that this will ignore newer replaced files with the same name!
                    continue

                print("  %s -> %s" % (v.name, ftp_path))
                with ftputil.FTPHost(*settings.ftp_args) as host:
                    with host.open(ftp_path, 'wb') as target:
                        try:
                            v.get_contents_to_file(target)
                        except Exception:
                            # On any failure, make sure any partly uploaded file isn't left behind
                            target.delete()
                            raise

        def attempt_with_retries(i=1):
            try:
                attempt_ftp_clone()
            except Exception:
                # On any failure...
                if i < 5:
                    # Just retry the entire backup. If this was a timeout error, the retry will now skip files
                    # successfully uploaded during the previous round and we'll hope that the remaining data is
                    # can be successfully uploaded during the next attempt without a new timeout.
                    attempt_with_retries(i+1)
                else:
                    # Can't seem to get rid of this failure - give up backuping and let it get sent to Sentry
                    raise

        # Start it
        attempt_with_retries()

except Exception as e:
    print((u"Exception (sent to Sentry): %s" % e.message).encode('utf-8'))
    raven.captureException()
    time.sleep(10) # Give raven time to send the error to Sentry
