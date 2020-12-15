SELECT to_json(c.*) FROM articulos_alfa c limit 10;
select row_to_json(row(id_articulo, articulo)) from articulo limit 10;

SELECT array_to_json(array_agg(*)) articulos_alfa limit 10;
SELECT * FROM json_each((SELECT to_json(*) articulos_alfa)) 
SELECT * FROM json_each('{ "id" : 1, "Nombre" : "Jorge" }')

SELECT ('{ ' || string_agg('"' || key || '" : ' || value, ', ') || ' }')::JSON FROM (
SELECT * FROM json_each('{ "id" : -1, "text" : "Jorge" }')
UNION ALL SELECT 'NuevoKey', '"NuevoValor"') t

SELECT to_json(c.*) FROM articulos_alfa c 
UNION ALL SELECT 'NuevoKey', '"NuevoValor"') t;

SELECT * FROM json_each('{ "id" : 1, "Nombre" : "Jorge" }')

SELECT ('[ ' || string_agg(value::TEXT, ', ') || ' ]')::JSON
FROM (SELECT * FROM json_array_elements('[{ "id" : -1, "text" : ""}]')
UNION ALL SELECT to_json(*) FROM articulos_alfa) t;

SELECT ('[ ' || string_agg(value::TEXT, ', ') || ' ]')::JSON
FROM (SELECT * FROM json_array_elements('[{ "id" : -1, "text" : "" }]')
UNION ALL SELECT to_json(t.*) FROM articulos_alfa t) t;

SELECT * FROM articulos_json;
