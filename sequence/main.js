"use strict";

var Sequelize = require('sequelize');
var _ = require("lodash");
var pg        = require('pg');

pg.defaults.parseInt8 = true;

let databaseName = 'line_execution'
let user = 'postgres'
let password = 'pass'
let host = 'localhost'
let constraint = `SELECT conname, parent_table, child_table, schema_name from (SELECT
    pc.conname ,
    --conrelid as child_table_id,
    pclsc.relname as child_table,
    pc.conkey as child_column_id,
    pac.attname as child_column,
    --confrelid as parent_table_id,
    pclsp.relname as parent_table,
    pc.confkey as parent_column_id,
    pap.attname as parent_column,
    nspname as schema_name
	FROM
    (
    SELECT
         connamespace,conname, unnest(conkey) as "conkey", unnest(confkey)
          as "confkey" , conrelid, confrelid, contype
     FROM
        pg_constraint
    ) pc
    JOIN pg_namespace pn ON pc.connamespace = pn.oid
    -- and pn.nspname = 'panmydesk4400'
    JOIN pg_class pclsc ON pc.conrelid = pclsc.oid
    JOIN pg_class pclsp ON      pc.confrelid = pclsp.oid
    JOIN pg_attribute pac ON pc.conkey = pac.attnum    and pac.attrelid =       pclsc.oid
    JOIN pg_attribute pap ON pc.confkey = pap.attnum and pap.attrelid = pclsp.oid

	ORDER BY pclsc.relname) as results
	where conname ~ '\\d$';`;

var sequelize = new Sequelize(
	databaseName,
	user,
	password, {
		host: host,
  	dialect: 'postgres',
		pool: {
			max: 5,
			min: 0,
			idle: 10000
		}
	});

let tablesQuery = `SELECT table_name AS name, column_name
      FROM information_schema.columns WHERE table_schema = 'public' and column_name='id' order by name`;

let tables = sequelize.query(tablesQuery, {
  replacements: [databaseName],
  type: sequelize.QueryTypes.SELECT
})

tables.then(function (results) {

	results.forEach(table => {

		var tableName = table.name;

		if(table.name=='group') tableName = '"'+tableName+'"';

		var column_name = table.column_name

		let getValuesQuery = `select MAX(${column_name}) FROM "${tableName}"`
		let getSequencesName = `select pg_get_serial_sequence('"${tableName}"', '${column_name}') as name`

		sequelize.query(getValuesQuery, {
		  type: sequelize.QueryTypes.SELECT
		}).then(function(tableCount){
			var sequenceValue = tableCount[0].max+1;

			if(sequenceValue>0){
				sequelize.query(getSequencesName, {
					type: sequelize.QueryTypes.SELECT
				}).then(function(sequenceResults){

					var sequenceName = sequenceResults[0].name
					let AlterSequenceQuery = `ALTER SEQUENCE ${sequenceName} RESTART WITH ${sequenceValue};`

					if(sequenceName!=null){

						sequelize.query(AlterSequenceQuery, {
							type: sequelize.QueryTypes.SELECT
						}).then(function(res){
							console.log(res)
						}).catch(function(err){
							console.log(err)
						})

					}
				})
			}
		}).catch(function(err){
			console.log(err)
		})
	})
}).catch(function(err){
	console.log(err)
});


// let constraint_name = sequelize.query(constraint, {
//   replacements: [databaseName],
//   type: sequelize.QueryTypes.SELECT
// });

// constraint_name.then( (results) =>{
// 	results.forEach(constraint => {
// 		let alterTable =`ALTER TABLE ${constraint.schema_name}.${constraint.child_table} DROP CONSTRAINT ${constraint.conname};`;
// 		sequelize.query(alterTable, {
// 			replacements: [databaseName], type: sequelize.QueryTypes.SELECT
// 		}).then( (deleted) =>{
// 			console.log('deleted', deleted);
// 		});
// 	});

// });


