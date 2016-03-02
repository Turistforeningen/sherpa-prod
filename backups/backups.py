#!/usr/bin/env python
from datetime import datetime, timedelta
import subprocess
import time

from sh import git, tar, rm
import boto
from raven import Client

import settings

raven = Client(dsn=settings.raven_url)
print("\nInitiating backup at: %s" % datetime.now()) # Set datestamp in output (which is logged), might be useful

try:
    dateformat = '%Y%m%d'
    now = datetime.now()

    # Keep 30 days of daily backups, 1 year of monthly backups, and unlimited yearly backups
    def clean_old_backups(buck, prefix, tarball, name):
        # Delete any month-old backup except for the first in the month
        then = now - timedelta(days=30)
        if then.day != 1:
            key_gz = boto.s3.key.Key(buck, name="%s%s-%s.%sgz" % (prefix, name, then.strftime(dateformat), 't' if tarball else ''))
            key_xz = boto.s3.key.Key(buck, name="%s%s-%s.%sxz" % (prefix, name, then.strftime(dateformat), 't' if tarball else ''))
            if key_gz.exists():
                key_gz.delete()
            if key_xz.exists():
                key_xz.delete()

    sherpa_bucket = [b for b in settings.buckets if b['name'] == 'turistforeningen'][0]
    conn = boto.connect_s3(sherpa_bucket['creds']['access_key'], sherpa_bucket['creds']['secret_key'])
    buck = conn.get_bucket('turistforeningen')

    #
    # Sherpa-databasen
    #

    print("Dumping sherpa db to S3...")
    name = 'sherpa'
    path = 'backups/sherpa/'
    filename = '%s-%s.xz' % (name, now.strftime(dateformat))

    key = boto.s3.key.Key(buck, name="%s%s" % (path, filename))
    db = subprocess.check_output([
        'docker exec db_postgres_1 /usr/bin/pg_dump -U postgres -Fc sherpa | xz --compress'
    ], stdin=subprocess.PIPE, shell=True)
    key.set_contents_from_string(db)

    clean_old_backups(buck, path, False, name)

    #
    # Kodebasen
    #

    print("Cloning git codebase and sending to S3...")
    name = 'sherpa'
    path = 'backups/kodebase/'
    filename = '%s-%s.txz' % (name, now.strftime(dateformat))

    git('clone', 'https://github.com/Turistforeningen/sherpa.git')
    tar('-cJf', filename, 'sherpa')

    key = boto.s3.key.Key(buck, name="%s%s" % (path, filename))
    key.set_contents_from_filename(filename)

    rm('-r', 'sherpa/')
    rm(filename)
    clean_old_backups(buck, path, True, name)

except Exception as e:
    print((u"Exception (sent to Sentry): %s" % e.message).encode('utf-8'))
    raven.captureException()
    time.sleep(10) # Give raven time to send the error to Sentry
