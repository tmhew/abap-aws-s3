class zaws_s3_list_objects_v2 definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.

    methods constructor.

    methods set_access_key importing access_key type string
                           returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_secret_key importing secret_key type string
                           returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_region importing region     type string
                       returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_bucket_name importing bucket_name type string
                            returning value(_me)  type ref to zaws_s3_list_objects_v2.

    methods set_continuation_token importing continuation_token type string
                                   returning value(_me)         type ref to zaws_s3_list_objects_v2.

    methods set_delimiter importing delimiter  type string
                          returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_encoding_type importing encoding_type type string
                              returning value(_me)    type ref to zaws_s3_list_objects_v2.

    methods set_fetch_owner importing fetch_owner type abap_bool default abap_true
                            returning value(_me)  type ref to zaws_s3_list_objects_v2.

    methods set_max_keys importing max_keys   type i default 1000
                         returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_prefix importing prefix     type string
                       returning value(_me) type ref to zaws_s3_list_objects_v2.

    methods set_start_after importing start_after type string
                            returning value(_me)  type ref to zaws_s3_list_objects_v2.

    methods execute exporting status_code type string
                              payload     type string.
  protected section.
  private section.
    types: begin of name_value_pair,
             name  type string,
             value type string,
           end of name_value_pair.

    types http_query_parameters type standard table of name_value_pair with key name.

    methods set_query_parameter importing name  type string
                                          value type string.

    data query_parameters type http_query_parameters.
    data access_key type string.
    data secret_key type string.
    data region type string.
    data bucket_name type string.
endclass.



class zaws_s3_list_objects_v2 implementation.
  method constructor.
    set_query_parameter( name = 'list-type' value = '2' ).
  endmethod.

  method set_access_key.
    me->access_key = access_key.
    _me = me.
  endmethod.

  method set_region.
    me->region = region.
    _me = me.
  endmethod.

  method set_secret_key.
    me->secret_key = secret_key.
    _me = me.
  endmethod.

  method set_bucket_name.
    me->bucket_name = bucket_name.
    _me = me.
  endmethod.

  method set_continuation_token.
    set_query_parameter( name = 'continuation-token' value = continuation_token ).
    _me = me.
  endmethod.

  method set_delimiter.
    set_query_parameter( name = 'delimiter' value = delimiter ).
    _me = me.
  endmethod.

  method set_encoding_type.
    set_query_parameter( name = 'encoding-type' value = encoding_type ).
    _me = me.
  endmethod.

  method set_fetch_owner.
    set_query_parameter(
      name  = 'fetch-owner'
      value = cond #( when fetch_owner = abap_true then 'true' else 'false' ) ).
    _me = me.
  endmethod.

  method set_max_keys.
    set_query_parameter( name = 'max-keys' value = |{ max_keys }| ).
    _me = me.
  endmethod.

  method set_prefix.
    set_query_parameter( name = 'prefix' value = prefix ).
    _me = me.
  endmethod.

  method set_start_after.
    set_query_parameter( name = 'start-after' value = start_after ).
    _me = me.
  endmethod.

  method set_query_parameter.
    read table query_parameters
      assigning field-symbol(<query_parameter>)
      with key name = name.

    if sy-subrc <> 0.
      append initial line to query_parameters assigning <query_parameter>.
      <query_parameter>-name = name.
    endif.

    <query_parameter>-value = value.
  endmethod.

  method execute.
    try.
        data(host) = |{ me->bucket_name }.s3.{ me->region }.amazonaws.com|.
        data(endpoint) = |https://{ host }|.

        zaws_sigv4_utilities=>get_current_timestamp( importing amz_date  = data(amzdate)
                                                               datestamp = data(datestamp) ).

        data(payload_hash) = zaws_sigv4_utilities=>get_hash( message = '' ).

        data(canonical_headers) = zaws_sigv4_utilities=>get_canonical_headers( value #(
          ( name = 'host' value = host )
          ( name = 'x-amz-date' value = amzdate )
          ( name = 'x-amz-content-sha256' value = payload_hash )
        ) ).

        data(signed_headers) = zaws_sigv4_utilities=>get_signed_headers( value #(
          ( name = 'host' )
          ( name = 'x-amz-date' )
          ( name = 'x-amz-content-sha256' )
        ) ).

        data(canonical_querystring) = zaws_sigv4_utilities=>get_canonical_querystring( query_parameters ).

        data(canonical_request) = zaws_sigv4_utilities=>get_canonical_request(
          http_method           = 'GET'
          canonical_uri         = '/'
          canonical_querystring = canonical_querystring
          canonical_headers     = canonical_headers
          signed_headers        = signed_headers
          payload_hash          = payload_hash
        ).

        data(algorithm) = zaws_sigv4_utilities=>get_algorithm( ).

        data(credential_scope) = zaws_sigv4_utilities=>get_credential_scope( datestamp = datestamp
                                                                             region    = region
                                                                             service   = 's3' ).

        data(string_to_sign) = zaws_sigv4_utilities=>get_string_to_sign( algorithm         = algorithm
                                                                         amz_date          = amzdate
                                                                         canonical_request = canonical_request
                                                                         credential_scope  = credential_scope ).

        data(signing_key) = zaws_sigv4_utilities=>get_signature_key( key          = secret_key
                                                                     datestamp    = datestamp
                                                                     region_name  = region
                                                                     service_name = 's3' ).

        data(signature) = zaws_sigv4_utilities=>get_signature( signing_key    = signing_key
                                                               string_to_sign = string_to_sign ).

        data(credential) = zaws_sigv4_utilities=>get_credential( access_key       = access_key
                                                                 credential_scope = credential_scope ).

        data(authorization_header) = zaws_sigv4_utilities=>get_authorization_header( algorithm      = algorithm
                                                                                     credential     = credential
                                                                                     signature      = signature
                                                                                     signed_headers = signed_headers ).

        cl_http_client=>create_by_url(
          exporting
            url    = |{ endpoint }?{ canonical_querystring  }|
          importing
            client = data(http_client)
        ).

        data(rest_client) = new cl_rest_http_client( io_http_client = http_client ).

        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-date' iv_value = amzdate ).
        rest_client->if_rest_client~set_request_header( iv_name = 'Authorization' iv_value = authorization_header ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-content-sha256' iv_value = payload_hash ).

        rest_client->if_rest_client~get( ).
        data(response) = rest_client->if_rest_client~get_response_entity( ).

        status_code = response->get_header_field( '~status_code' ).
        payload = response->get_string_data(  ).

      catch cx_root into data(x_root).
        "Do something
    endtry.
  endmethod.

  method if_oo_adt_classrun~main.
    data(lo_s3) = new zaws_s3_list_objects_v2( ).
    lo_s3->set_access_key( '' ).
    lo_s3->set_secret_key( '' ).
    lo_s3->set_bucket_name( '' ).
    lo_s3->set_region( 'us-east-1' ).

*    lo_s3->set_continuation_token( '' ).
    lo_s3->set_max_keys( 1 ).


    lo_s3->execute( importing status_code = data(status_code)
                              payload     = data(payload) ).

    out->write( status_code ).
    out->write( payload ).

  endmethod.

endclass.
