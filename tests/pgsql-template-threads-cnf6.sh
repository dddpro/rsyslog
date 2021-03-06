#!/bin/bash
# This file is part of the rsyslog project, released under GPLv3

. $srcdir/diag.sh init

psql -h localhost -U postgres -f testsuites/pgsql-basic.sql

. $srcdir/diag.sh generate-conf
. $srcdir/diag.sh add-conf '
template(name="pgtemplate" type="list" option.sql="on") {
	constant(value="INSERT INTO SystemEvents (SysLogTag) values ('"'"'")
	property(name="msg")
	constant(value="'"'"')")
}

module(load="../plugins/ompgsql/.libs/ompgsql")
if $msg contains "msgnum" then {
	action(type="ompgsql" server="127.0.0.1"
		db="syslogtest" user="postgres" pass="testbench"
		template="pgtemplate" queue.workerthreads="4")
}'

. $srcdir/diag.sh startup
. $srcdir/diag.sh injectmsg  0 5000
. $srcdir/diag.sh shutdown-when-empty
. $srcdir/diag.sh wait-shutdown


psql -h localhost -U postgres -d syslogtest -f testsuites/pgsql-select-syslogtag.sql -t -A > rsyslog.out.log 

. $srcdir/diag.sh seq-check  0 4999

echo cleaning up test database
psql -h localhost -U postgres -c 'DROP DATABASE IF EXISTS syslogtest;'

. $srcdir/diag.sh exit
