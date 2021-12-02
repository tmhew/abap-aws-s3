class zaws_s3_get_object definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.

    methods set_access_key importing access_key type string
                           returning value(_me) type ref to zaws_s3_get_object.

    methods set_secret_key importing secret_key type string
                           returning value(_me) type ref to zaws_s3_get_object.

    methods set_region importing region     type string
                       returning value(_me) type ref to zaws_s3_get_object.

    methods set_bucket_name importing bucket_name type string
                            returning value(_me)  type ref to zaws_s3_get_object.

    methods set_object_key importing object_key type string
                           returning value(_me) type ref to zaws_s3_get_object.

    methods execute exporting status_code type string
                              payload     type xstring.

  protected section.
  private section.
    data access_key type string.
    data secret_key type string.
    data region type string.
    data bucket_name type string.
    data object_key type string.
endclass.



class zaws_s3_get_object implementation.
  method set_access_key.
    me->access_key = access_key.
    _me = me.
  endmethod.

  method set_secret_key.
    me->secret_key = secret_key.
    _me = me.
  endmethod.

  method set_region.
    me->region = region.
    _me = me.
  endmethod.

  method set_bucket_name.
    me->bucket_name = bucket_name.
    _me = me.
  endmethod.

  method set_object_key.
    me->object_key = object_key.
    _me = me.
  endmethod.

  method execute.
    try.
        data(host) = |{ me->bucket_name }.s3.{ me->region }.amazonaws.com|.
        data(endpoint) = |https://{ host }/{ me->object_key }|.

        data(payload_hash) = zaws_sigv4_utilities=>get_hash( message = '' ).

        zaws_sigv4_utilities=>get_current_timestamp( importing amz_date  = data(amzdate)
                                                               datestamp = data(datestamp) ).

        data(canonical_headers) = zaws_sigv4_utilities=>get_canonical_headers( http_headers = value #(
                                                                               ( name = 'host' value = host )
                                                                               ( name = 'x-amz-date' value = amzdate )
                                                                               ( name = 'x-amz-content-sha256' value = payload_hash )
                                                                               ) ).

        data(signed_headers) = zaws_sigv4_utilities=>get_signed_headers( http_header_names = value #(
                                                                         ( name = 'host' )
                                                                         ( name = 'x-amz-date' )
                                                                         ( name = 'x-amz-content-sha256' )
                                                                         ) ).

        data(canonical_request) = zaws_sigv4_utilities=>get_canonical_request(
          http_method           = 'GET'
          canonical_uri         = |/{ me->object_key }|
          canonical_querystring = ''
          canonical_headers     = canonical_headers
          signed_headers        = signed_headers
          payload_hash          = payload_hash
        ).

        data(algorithm) = zaws_sigv4_utilities=>get_algorithm( ).

        data(credential_scope) = zaws_sigv4_utilities=>get_credential_scope( datestamp = datestamp
                                                                             region    = me->region
                                                                             service   = 's3' ).

        data(string_to_sign) = zaws_sigv4_utilities=>get_string_to_sign( algorithm         = algorithm
                                                                         amz_date          = amzdate
                                                                         canonical_request = canonical_request
                                                                         credential_scope  = credential_scope ).

        data(signing_key) = zaws_sigv4_utilities=>get_signature_key( key          = me->secret_key
                                                                     datestamp    = datestamp
                                                                     region_name  = me->region
                                                                     service_name = 's3' ).

        data(signature) = zaws_sigv4_utilities=>get_signature( signing_key    = signing_key
                                                               string_to_sign = string_to_sign ).

        data(credential) = zaws_sigv4_utilities=>get_credential( access_key       = me->access_key
                                                                 credential_scope = credential_scope ).

        data(authorization_header) = zaws_sigv4_utilities=>get_authorization_header( algorithm      = algorithm
                                                                                     credential     = credential
                                                                                     signature      = signature
                                                                                     signed_headers = signed_headers ).

        cl_http_client=>create_by_url(
          exporting
            url    = endpoint
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
        payload = response->get_binary_data( ).

      catch cx_root into data(x_root).
        "Do something?
    endtry.
  endmethod.

  method if_oo_adt_classrun~main.
    data(lo_s3) = new zaws_s3_get_object( ).
    lo_s3->set_access_key( '' ).
    lo_s3->set_secret_key( '' ).
    lo_s3->set_bucket_name( '' ).
    lo_s3->set_object_key( 'hello-world/welcome.txt' ).
    lo_s3->set_region( 'us-east-1' ).

    lo_s3->execute( importing status_code = data(status_code)
                              payload = data(payload) ).

    out->write( status_code ).
    data content type string.
    cl_abap_conv_in_ce=>create( encoding = 'UTF-8' input = payload )->read( importing data = content ).
    out->write( content ).

  endmethod.

endclass.
