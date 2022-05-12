create index real_property_master_documentid_idx on real_property_master(documentid);
create index real_property_legals_documentid_idx on real_property_legals(documentid);
create index real_property_parties_documentid_idx on real_property_parties(documentid);


--alter table real_property_master alter column borough type smallint USING borough::smallint;
create index real_property_legals_borough_idx on real_property_legals(borough);
/* TODO: revert these number conversion, useless */
--alter table real_property_legals alter column borough type smallint USING borough::smallint;
--alter table real_property_legals alter column lot type smallint USING lot::smallint;
--alter table real_property_legals alter column block type integer USING block::integer;

--create index real_property_legals_borough_idx on real_property_legals(borough);
--create index real_property_legals_block_idx on real_property_legals(block);
--create index real_property_legals_lot_idx on real_property_legals(lot);


/* Add bbl columns and index it. */
ALTER TABLE real_property_legals ADD COLUMN "bbl" text;
UPDATE real_property_legals SET bbl = concat(borough,'-',LPAD(block::text, 5, '0'),'-',LPAD(lot::text, 4, '0'));
create index real_property_legals_bbl_idx on real_property_legals(bbl);

alter table real_property_master alter column docamount type numeric(16,2) USING docamount::numeric(16,2);
create index real_property_master_docamount_idx on real_property_master (docamount);

create materialized view real_property_parties_by_documentid as select documentid, array_agg(name) filter (where partytype = '1') as party1, array_agg(name) filter (where partytype = '2') as party2, array_agg(name) filter (where partytype = '3') as party3 from real_property_parties group by documentid;
CREATE UNIQUE INDEX real_property_parties_by_documentid_documentid_idx ON real_property_parties_by_documentid (documentid);

/*
create index real_property_master_docdate_idx on real_property_master (docdate);

create materialized view real_property_legals_by_documentid as select documentid, array_agg(concat(streetnumber, ' ', streetname)) as properties from real_property_legals group by documentid;
CREATE UNIQUE INDEX real_property_legals_by_documentid_documentid_idx ON real_property_legals_by_documentid (documentid);

create view real_property_master_denormalized as select m.*, l.properties, p.party1, p.party2, p.party3 from real_property_master m join real_property_legals_by_documentid l on m.documentid = l.documentid join real_property_parties_by_documentid p on p.documentid = m.documentid;
*/

create materialized view bbl_latest_money_doc AS SELECT DISTINCT ON (a.bbl, m.doctype)
  m.documentid,
  a.bbl,
  concat(a.streetnumber, ' ', a.streetname) as address,
  a.propertytype,
  m.doctype,
  m.docdate,
  m.docamount
FROM real_property_legals a 
LEFT JOIN real_property_master m USING (documentid) WHERE m.docamount > 100000 AND m.doctype IN ('DEED', 'MTGE') AND m.docdate > '2000-01-01' order by a.bbl, m.doctype, m.docdate desc NULLS LAST

