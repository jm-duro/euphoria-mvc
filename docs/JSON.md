# JSON

The JSON parser parses JSON into Euphoria sequences.

## Available data types

JSON elements can be classified as one of five types:

- `JSON_OBJECT` - an key/value list of elements
- `JSON_ARRAY` - a sequential list of elements
- `JSON_STRING` - any valid string value
- `JSON_NUMBER` - any valid number value
- `JSON_PRIMITIVE` - one of only `true`, `false`, or `null`

## Returning data types

Parsed JSON elements will always be returned as `{type,value}`. For example, a parsed string will return `{JSON_STRING,"the string value"}`, a parsed number will return `{JSON_NUMBER,12345}`, etc.

## Reporting parser errors

If a value cannot be parsed, the returned value will be `{JSON_NONE,0}`. You can use the string stored in the global variable `json_last_error` to determine what may have gone wrong.

## Example

    include mvc/json.e

    object json_data = json_parse(`{
        "name": "John Smith",
        "age": 42,
        "address": "123 Easy St",
        "phones": [
            "(989) 555-1234",
            "(616) 555-9876" 
        ]
    }`)

    sequence name = json_fetch( json_data, "name" )
    -- name is {JSON_STRING,"John Smith"}

    integer  age = json_fetch( json_data, "age" )
    -- age is {JSON_NUMBER,42}

    sequence address = json_fetch( json_data, "address" )
    -- address is {JSON_STRING,"123 East St"}

    sequence phones = json_fetch( json_data, "phones" )
    -- phones is {JSON_ARRAY,{
    --   {JSON_STRING,"(989) 555-1234"},
    --   {JSON_STRING,"(616) 555-9876"}
    -- }}

## Parser routines

* [`json_append`](#json_append)
* [`json_compare`](#json_compare)
* [`json_fetch`](#json_fetch)
* [`json_haskey`](#json_haskey)
* [`json_import`](#json_import)
* [`json_markup`](#json_markup)
* [`json_parse`](#json_parse)
* [`json_parse_file`](#json_parse_file)
* [`json_print`](#json_print)
* [`json_remove`](#json_remove)
* [`json_sprint`](#json_sprint)

### json_append

`include mvc/json.e`  
`public function json_append( object json_target, object json_object )`

Appends one JSON value onto another. Objects of type `JSON_NUMBER` or `JSON_PRIMITIVE` will be converted to `JSON_ARRAY`. Objects of type `JSON_ARRAY` or `JSON_STRING` will be concatenated together. Objects of type `JSON_OBJECT` will have the key/value pairs from **json_object** simply appended to the end of **json_target**. Absolutely no checking for duplicate keys is done at this time.

**Parameters**

- **`json_target`** - the object being appended to
- **`json_object`** - the object whose values will be appended to **json_target**

**Returns**

- The updated version of **json_target** with the values from **json_object** appended to it.

### json_compare

`include mvc/json.e`  
`public function json_compare( sequence json_a, sequence json_b )`

Performs a "deep" comparison of two parsed JSON values. This will decend into key/value pairs and ensure they're all compared correctly.

**Parameters**

- **`json_a`** - a parsed JSON value
- **`json_b`** - a parsed JSON value

**Returns**

- Returns `-1` if `json_a` is *less than* `json_b`.
- Returns `0` if `json_a` is *equal to* `json_b`.
- Returns `1` if `json_a` is *greater than* `json_b`.

### json_fetch

`include mvc/json.e`  
`public function json_fetch( object json_object, sequence keys, object sep = '.' )`

Fetches a nested value from inside JSON object using the provided keys.

**Parameters**

- **`json_object`** - a value returned from `json_parse`
- **`keys`** - a string of keys separated by **sep** (e.g. `"user.name"`) or a sequence of keys (e.g. `{"user","name"}`)
- **`sep`** - a string or character to act as a separator for **keys**

**Returns**

The requeted value. See `json_parse` for possible return values and types.

### json_haskey

`include mvc/json.e`  
`public function json_haskey( object json_object, sequence keys, object sep = '.' )`

Returns `TRUE` if the value of **keys** exists in **json_object**.

**Parameters**

- **`json_object`** - the object whose keys will be searched (this should be a `JSON_OBJECT` value)
- **`keys`** - a string of keys separated by **sep** (e.g. `"user.name"`) or a sequence of keys (e.g. `{"user","name"}`)
- **`sep`** - a string or character to act as a separator for **keys**

**Returns**

Returns `TRUE` if the key or nested key path exists in the **json_object**.

### json_import

`include mvc/json.e`  
`public function json_import( object map_object )`

Imports the key/value pairs from a map to a `JSON_OBJECT` value.

Please keep in mind that this function has significant limits:

- Only string keys are allowed (this is a JSON limitation).
- Only number and string values are allowed (this is a Euphoria limitation).

**Parameters**

- **`map_object`** - the map containing key/value pairs to import

**Returns**

A sequence containing `{type,value}` where `type` is `JSON_OBJECT` if the map was parsed correctly, or `JSON_NONE` if there was an error, in which case check the output of `json_last_error()` for the reason.

### json_markup

`include mvc/json.e`  
`public function json_markup( object json_object, integer sorted_keys = TRUE, integer white_space = TRUE, integer indent_width = 4, integer start_column = 0 )`

Similar to `json_sprint` but it formats the parsed JSON value into Euphoria "markup" which should be valid Euphoria code. This is useful for debugging or validating the JSON parser output, or caching data in native Euphoria code files.

**Parameters**

- **`json_object`** - a value returned from `json_parse`
- **`sorted_keys`** - if `TRUE`, print `JSON_OBJECT` keys in sorted order
- **`white_space`** - if `TRUE`, insert white space to "pretty print" data
- **`indent_width`** - number of spaces to indent when printing white space
- **`start_column`** - number of spaces to indent the entire output

**Returns**

The formatted string containing the Euphora markup of a JSON object.

**Remarks**

If you want to use the output as Euphoria code, remember to add a line for  `include mvc/json.e` to your code file.

### json_parse

`include mvc/json.e`  
`public function json_parse( string js )`

Parses a string and returns the JSON type and value.

**Parameters**

- **`js`** - the literal string containing JSON data

**Returns**

A sequence containing `{type,value}` where `type` is one of:

- `JSON_OBJECT` - a key/value list, `value` is a sequence of `{key,{type,value}}` elements
- `JSON_ARRAY` - a sequential list, `value` is a sequence of `{type,value}` elements
- `JSON_STRING` - a string, `value` is a Euphoria string (sequence)
- `JSON_NUMBER` - a number, `value` is a Euphoria atom or integer
- `JSON_PRIMITIVE` - a primitive, `value` is a string contianing `"true"`, `"false"`, or `"null"`
- `JSON_NONE` - something went wrong and `value` will be zero (`0`)

If the return type is `JSON_NONE` check `json_last_error` for an error message.

### json_parse_file

`include mvc/json.e`  
`public function json_parse_file( string file_name )`

Parses a file and returns the JSON type and value.

**Parameters**

- **`file_name`** - the path to the file containing JSON data

**Returns**

See `json_parse` for possible return values and types.

### json_print

`include mvc/json.e`  
`public procedure json_print( object fn, sequence json_object, integer sorted_keys = TRUE, integer white_space = FALSE, integer indent_width = 4, integer start_column = 0 )`

Writes a parsed JSON value from `json_parse` to a file in its native structure. Optionally can insert white space to "pretty print" the data.

**Parameters**

- **`fn`** - an open file number or a file name to open, write, and close
- **`json_object`** - a value returned from `json_parse`
- **`sorted_keys`** - if `TRUE`, print `JSON_OBJECT` keys in sorted order
- **`white_space`** - if `TRUE`, insert white space to "pretty print" data
- **`indent_width`** - number of spaces to indent when printing white space
- **`start_column`** - number of spaces to indent the entire output

### json_remove

`include mvc/json.e`  
`public function json_remove( object json_object, sequence keys, object sep = '.' )`

Removes a nested value from inside JSON object using the provided keys.

**Parameters**

- **`json_object`** - the object whose keys will be searched (this should be a `JSON_OBJECT` value)
- **`keys`** - a string of keys separated by **sep** (e.g. `"user.name"`) or a sequence of keys (e.g. `{"user","name"}`)
- **`sep`** - a string or character to act as a separator for **keys**

**Returns**

The updated **json_object** with the value of **keys** removed.

### json_sprint

`include mvc/json.e`  
`public function json_sprint( sequence json_object, integer sorted_keys = TRUE, integer white_space = FALSE, integer indent_width = 4, integer start_column = 0 )`

Formats a parsed JSON value from `json_parse` back into its native structure. Optionally can insert white space to "pretty print" the data.

**Parameters**

- **`json_object`** - a value returned from `json_parse`
- **`sorted_keys`** - if `TRUE`, print `JSON_OBJECT` keys in sorted order
- **`white_space`** - if `TRUE`, insert white space to "pretty print" data
- **`indent_width`** - number of spaces to indent when printing white space
- **`start_column`** - number of spaces to indent the entire output

**Returns**

The formatted string containing the native JSON structures.
