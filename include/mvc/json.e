
namespace json

include std/get.e
include std/io.e
include std/pretty.e
include std/sequence.e
include std/sort.e
include std/types.e

public enum
    J_TYPE,
    J_VALUE

export sequence json_last_error = ""

export enum type jsontype_t
    JSON_NONE = 0,
    JSON_OBJECT,
    JSON_ARRAY,
    JSON_STRING,
    JSON_NUMBER,
    JSON_PRIMITIVE
end type

export function json_skip_whitespace( string js, integer start )

    integer i = start

    while i <= length( js ) and t_space( js[i] ) do
        i += 1
    end while

    return i
end function

function compare_keys( sequence json_a, sequence json_b )
    return compare( json_a[1], json_b[1] )
end function

function sort_by_key( sequence pairs )
    return custom_sort( routine_id("compare_keys"), pairs )
end function

export function json_parse_object( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer i = json_skip_whitespace( js, start )
    integer last_i = i

    if i <= length( js ) and js[i] != '{' then
        json_last_error = sprintf( "json_parse_object(): Expected '{' at position %d", i )
        return {json_type,json_value,i}
    end if

    json_value = {}
    i = json_skip_whitespace( js, i+1 )

    while i <= length( js ) do

        integer key_type, value_type
        object key_object, value_object

        last_i = i
        {key_type,key_object,i} = json_parse_value( js, i )

        if key_type != JSON_STRING then
            json_last_error = sprintf( "json_parse_object(): Expected string at position %d", last_i )
            exit
        end if

        i = json_skip_whitespace( js, i )

        if js[i] != ':' then
            json_last_error = sprintf( "json_parse_object(): Expected ':' at position %d", i )
            exit
        end if

        i = json_skip_whitespace( js, i+1 )

        last_i = i
        {value_type,value_object,i} = json_parse_value( js, i )

        if value_type = JSON_NONE then
            json_last_error = sprintf( "json_parse_object(): Expected object at position %d", last_i )
            exit
        end if

        json_value = append( json_value, {key_object,{value_type,value_object}}  )

        i = json_skip_whitespace( js, i )

        if js[i] = '}' then
            json_type = JSON_OBJECT
            i += 1
            exit
        end if

        if js[i] != ',' then
            json_last_error = sprintf( "json_parse_object(): Expected ',' at position %d", i )
            exit
        end if

        i += 1
    end while

    if json_type = JSON_NONE then
        delete( json_value )
        json_value = 0
    end if

    return {json_type,json_value,i}
end function

export function json_parse_array( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer i = json_skip_whitespace( js, start )
    integer last_i = i

    if i <= length( js ) and js[i] != '[' then
        json_last_error = sprintf( "json_parse_array(): Expected '[' at position %d", i )
        return {json_type,json_value,i}
    end if

    json_value = {}
    i = json_skip_whitespace( js, i+1 )

    while i <= length( js ) do

        integer member_type
        object member_value

        {member_type,member_value,i} = json_parse_value( js, i )

        if member_type = JSON_NONE then
            json_last_error = sprintf( "json_parse_array(): Expected object at position %d", last_i )
            exit
        end if

        json_value = append( json_value, {member_type,member_value} )

        i = json_skip_whitespace( js, i )

        if js[i] = ']' then
            json_type = JSON_ARRAY
            i += 1
            exit
        end if

        if js[i] != ',' then
            json_last_error = sprintf( "json_parse_array(): Expected ',' at position %d", i )
            exit
        end if

        i += 1
    end while

    return {json_type,json_value,i}
end function

export function json_parse_string( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer i = start

    if i <= length( js ) and js[i] != '"' then
        json_last_error = sprintf( "json_parse_string(): Expected '\"' at position %d", i )
        return {json_type,json_value,i}
    end if

    object get_status, get_result, get_offset
    {get_status,get_result,get_offset,?} = stdget:value( js, i, GET_LONG_ANSWER )

    i += get_offset

    if get_status = GET_SUCCESS and string( get_result ) then
        json_type = JSON_STRING
        json_value = get_result
    else
        json_last_error = sprintf( "json_parse_string(): Expected string at position %d", i )
    end if        

    return {json_type,json_value,i}
end function

export function json_parse_number( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0
    
    integer i = start
    
    if i <= length( js ) and find( js[i], "-0123456789" ) = 0 then
        json_last_error = sprintf( "json_parse_number(): Expected digit or '-' at position %d", i )
        return {json_type,json_value,i}
    end if

    object get_status, get_result, get_offset
    {get_status,get_result,get_offset,?} = stdget:value( js, i, GET_LONG_ANSWER )

    i += get_offset

    if get_status = GET_SUCCESS and atom( get_result ) then
        json_type = JSON_NUMBER
        json_value = get_result
    else
        json_last_error = sprintf( "json_parse_number(): Expected number at position %d", i )
    end if        

    return {json_type,json_value,i}
end function

export function json_parse_primitive( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer i = json_skip_whitespace( js, start )
    integer last_i = i
    
    json_value = ""

    while i <= length( js ) and t_alpha( js[i] ) do
        json_value &= js[i]
        i += 1
    end while

    if find( json_value, {"true","false","null"} ) then
        json_type = JSON_PRIMITIVE
    else
        json_last_error = sprintf( "json_parse_primitive(): Expected one of (true,false,null) at position %d", last_i )
    end if

    return {json_type,json_value,i}
end function

export function json_parse_value( string js, integer start )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer i = json_skip_whitespace( js, start )

    if i <= length( js ) then

        switch js[i] do
    
            case '{' then
                {json_type,json_value,i} = json_parse_object( js, i )

            case '[' then
                {json_type,json_value,i} = json_parse_array( js, i )

            case '"' then
                {json_type,json_value,i} = json_parse_string( js, i )

            case '-','0','1','2','3','4','5','6','7','8','9' then
                {json_type,json_value,i} = json_parse_number( js, i )

            case 't','f','n' then
                {json_type,json_value,i} = json_parse_primitive( js, i )

        end switch

    end if

    return {json_type,json_value,i}
end function

public function json_parse( string js )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    json_last_error = ""
    {json_type,json_value,?} = json_parse_value( js, 1 )

    return {json_type,json_value}
end function

public function json_parse_file( string file_name )

    jsontype_t json_type = JSON_NONE
    object json_value = 0

    integer fn = open( file_name, "rb" )

    if fn = -1 then
        json_last_error = sprintf( "Could not read file \"%s\"", {file_name} )
        return {json_type,json_value}
    end if

    sequence js = read_file( fn )

    close( fn )

    return json_parse( js )
end function

public function json_sprint( sequence json_object, integer sorted_keys = TRUE, integer white_space = FALSE, integer indent_width = 4, integer start_column = 0 )

    sequence inner_pad, outer_pad, one_space, line_break

	if white_space then
		inner_pad = repeat( ' ', (start_column+1) * indent_width )
        outer_pad = repeat( ' ', (start_column+0) * indent_width )
        one_space = " "
		line_break = "\n"
	else
		inner_pad = ""
        outer_pad = ""
        one_space = ""
		line_break = ""
	end if

    string s = ""

    switch json_object[J_TYPE] do

        case JSON_OBJECT then

            sequence pairs = json_object[J_VALUE]

            if sorted_keys then
                pairs = sort_by_key( pairs )
            end if

            s &= "{"
            s &= line_break

            for i = 1 to length( pairs ) do

                s &= inner_pad
                s &= sprintf( `"%s":`, {pairs[i][1]} )
                s &= one_space
                s &= json_sprint( pairs[i][2], sorted_keys, white_space, indent_width, start_column+1 )

                if i < length( pairs ) then
                    s &= ","
                end if

                s &= line_break

            end for

            s &= outer_pad
            s &= "}"

        case JSON_ARRAY then

            sequence items = json_object[J_VALUE]

            s &= "["
            s &= line_break

            for i = 1 to length( items ) do

                s &= inner_pad
                s &= json_sprint( items[i], sorted_keys, white_space, indent_width, start_column+1 )

                if i < length( items ) then
                    s &= ","
                end if

                s &= line_break

            end for

            s &= outer_pad
            s &= "]"

        case JSON_STRING then
            s &= sprintf( `"%s"`, {json_object[J_VALUE]} )

        case JSON_NUMBER then
            s &= sprintf( `%g`, {json_object[J_VALUE]} )

        case JSON_PRIMITIVE then
            s &= sprintf( `%s`, {json_object[J_VALUE]} )
            
    end switch

    return s
end function

public procedure json_print( integer fn, sequence json_object, integer sorted_keys = TRUE, integer white_space = FALSE, integer indent_width = 4, integer start_column = 0 )

    if string( fn ) then
        fn = open( fn, "wb", TRUE )
    end if

    puts( fn, json_sprint(json_object, sorted_keys, white_space, indent_width, start_column) )
    
end procedure

sequence PRETTY_MARKUP = PRETTY_DEFAULT
PRETTY_MARKUP[DISPLAY_ASCII] = 2 -- display as "string"
PRETTY_MARKUP[LINE_BREAKS]   = 0 -- no line breaks

public function json_markup( object json_object, integer sorted_keys = TRUE, integer white_space = TRUE, integer indent_width = 4, integer start_column = 0 )

    sequence inner_pad, outer_pad, one_space, line_break

	if white_space then
		inner_pad = repeat( ' ', (start_column+1) * indent_width )
        outer_pad = repeat( ' ', (start_column+0) * indent_width )
        one_space = " "
		line_break = "\n"
	else
		inner_pad = ""
        outer_pad = ""
        one_space = ""
		line_break = ""
	end if

    string s = "{"

    switch json_object[J_TYPE] do

        case JSON_OBJECT then

            s &= "JSON_OBJECT,"
            s &= one_space

            sequence pairs = json_object[J_VALUE]

            if sorted_keys then
                pairs = sort_by_key( pairs )
            end if

            s &= "{"
            s &= line_break

            for i = 1 to length( pairs ) do

                s &= inner_pad
                s &= "{"
                s &= sprintf( `"%s",`, {pairs[i][1]} )
                s &= one_space
                s &= json_markup( pairs[i][2], sorted_keys, white_space, indent_width, start_column+1 )
                s &= "}"

                if i < length( pairs ) then
                    s &= ","
                end if

                s &= line_break

            end for

            s &= outer_pad
            s &= "}"

        case JSON_ARRAY then

            s &= "JSON_ARRAY,"
            s &= one_space

            sequence items = json_object[J_VALUE]

            s &= "{"
            s &= line_break

            for i = 1 to length( items ) do

                s &= inner_pad
                s &= json_markup( items[i], sorted_keys, white_space, indent_width, start_column+1 )

                if i < length( items ) then
                    s &= ","
                end if

                s &= line_break

            end for

            s &= outer_pad
            s &= "}"

        case JSON_STRING then
            s &= "JSON_STRING,"
            s &= one_space
            s &= pretty_sprint( json_object[J_VALUE], PRETTY_MARKUP )

        case JSON_NUMBER then
            s &= "JSON_NUMBER,"
            s &= one_space
            s &= pretty_sprint( json_object[J_VALUE], PRETTY_MARKUP )

        case JSON_PRIMITIVE then
            s &= "JSON_PRIMITIVE,"
            s &= one_space
            s &= sprintf( `"%s"`, {json_object[J_VALUE]} )
            
    end switch

    s &= '}'

    return s
end function

public function json_compare( sequence json_a, sequence json_b )

    integer result
    
    result = compare( json_a[J_TYPE], json_b[J_TYPE] )
    if result != 0 then
        return result
    end if

    if json_a[J_TYPE] = JSON_OBJECT then
        
        sequence pairs_a = json_a[J_VALUE]
        sequence pairs_b = json_b[J_VALUE]

        if length( pairs_a ) != length( pairs_b ) then
            return length( pairs_a ) - length( pairs_b )
        end if

        for i = 1 to length( pairs_a ) do

            result = json_compare(
                pairs_a[i][2],
                pairs_b[i][2]
            )

            if result != 0 then
                exit
            end if

        end for

        return result

    elsif json_a[J_TYPE] = JSON_ARRAY then

        for i = 1 to length( json_a[J_VALUE] ) do

            result = json_compare(
                json_a[J_VALUE][i],
                json_b[J_VALUE][i]
            )

            if result != 0 then
                exit
            end if

        end for

        return result

    end if

    result = compare( json_a[J_VALUE], json_b[J_VALUE] )

    return result
end function

public function json_fetch( object json_object, sequence keys )

    if string( keys ) then
        keys = stdseq:split( keys, '.' )
    end if

    integer i = 1

    while json_object[J_TYPE] = JSON_OBJECT and i <= length( keys ) do

        integer found = 0

        for j = 1 to length( json_object[J_VALUE] ) do

            if equal( json_object[J_VALUE][j][1], keys[i] ) then
                found = j
                json_object = json_object[J_VALUE][j][2]
                exit
            end if

        end for

        if found = 0 then
            json_object = {JSON_NONE,0}
            exit
        end if

        i += 1
    end while

    return json_object
end function