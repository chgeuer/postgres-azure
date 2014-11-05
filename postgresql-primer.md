
# PostgreSQL Primer

- PostgreSQL developers are employed by a variety of companies, therefore the OSS dev team tries to re-use as much as possible
- PostgreSQL is pretty robust. One customer hat 3-5 bluescreens per week, without data corruption
- Two different data storages
	- General ledger == Write Ahead Log (WAL) records, "I will do the following", + fsync. Write caching is really bad here. Pure sequential writes. This must be written before a commit can be done. 
	- Dann noch die eigentlichen DB files
- Wenn die Tables nicht in Sync mit dem WAL record ist, wird postgres in den recovery modus gesetzt. 
- WAL records können auf andere Systeme kopiert werden (in 16MB chunks), WAL shipping, z.B. 
	- für einen nachlaufenden Slave
	- Point in time recovery
	- Backup
	- Anderen Storage (S3, Glacier)
	- WAL records (binäre diffs) haben immer 16MB; können aber schon verschickt werden, wenn die 16MB noch nicht voll sind. (PGX log verzeichnis), rufen eine Shell auf, die irgendwas macht (archive command)
	- Seit 9.0 können WAL records auch per "streaming replication" versendet werden (bytes an einen TCP Port senden)
	- Wenn man "streaming replication" oder "WAL shipping" auf einen secondary server machen, ist der gewissermaßen immer im Recovery Modus. Auch wenn der Server im "Recovery Modus" ist, kann man lese-Queries dagegen schicken
	- 9.0 mach async streaming machen
	- 9.1 kann synchronous streaming replication erzwingen (garantiert auf mindestens einem Streaming Slave). Dieser Slave ist immer der erste in der Liste der Slaves. 
	- "Synchronous streaming replicatoin" kann man auch für einzelne Transaktionen einschalten, also z.B. nur für wichtige Writes. 
	- Trigger-basierte replication ("Slony" und "Londiste" sind trigger-based replication implementations). Slony (fragile C Code Base), Londiste (Python) . Diesen Trigger (on-update / on-insert) setzt man auf eine Datenbank. Londiste kommt von Skype. Londiste schreibt Änderungen in eine Queue in Postgres (Listen&Notify) rein. 
	- Londiste nutzt man für "cross-version upgrade", 
	- Trigger-based replication kann Probleme bei Schema-Updates erzeugen
	- Jedes Byte, welches in einer Tabelle geschrieben wird, sind mindestens 2 Bytes Festplatten-I/O
	- Ab 9.4 gibt es "Logical decoding", welches aus einem WAL Record rekonstruieren kann, was auf Anwendungsebene wohl passiert ist (menschenlesbar)
	- Logical Decoding used for multi-master replication (bi-directional replication sync hin- und her)
	- Problem ist in geo-verteilten Datacentern mit high latency. US-Datenbank für US-Kunden, EU-Datenbank für EU Kunden, und mit bi-directional replication alle Daten überall, die Daten der Kollegen halt etwas später (5 mins)
	- Streaming Replication ermöglicht "Read Scaling", also schreiben auf eine einzelne DB, und aus mehreren Read-Slaves rauslesen. Man kann in einem View schauen, wie weit der Slave hinterher ist. 
	- Die Read-Slaves können zum Master promoted werden, wird von Read-Only zu Read-Write. Mit PGBouncer und DNS die Clients umbiegen. Wenn der Master wieder hochkommt, wird per RSYNC die letzten Änderungen vom neuen Master auf den wieder hochkommenden alten Master repliziert. (rep manager www.repmgr.org) 
	- PostgreSQL forked bei neuen Verbindungen. pgBouncer ist ein Service, der Connection-Pooling für mis-behaving clients anbietet. pgBouncer authentifiziert Clients. 
		
