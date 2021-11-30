class zaws_s3_put_object definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.

    methods set_access_key importing access_key type string
                           returning value(_me) type ref to zaws_s3_put_object.

    methods set_secret_key importing secret_key type string
                           returning value(_me) type ref to zaws_s3_put_object.

    methods set_region importing region     type string
                       returning value(_me) type ref to zaws_s3_put_object.

    methods set_bucket_name importing bucket_name type string
                            returning value(_me)  type ref to zaws_s3_put_object.

    methods set_object_key importing object_key type string
                           returning value(_me) type ref to zaws_s3_put_object.

    methods set_object_payload importing object_payload type string
                               returning value(_me)     type ref to zaws_s3_put_object.

    methods set_content_type importing content_type type string
                             returning value(_me)   type ref to zaws_s3_put_object.

    methods execute returning value(response_headers) type tihttpnvp.

  protected section.
  private section.
    data access_key type string.
    data secret_key type string.
    data region type string.
    data bucket_name type string.
    data object_key type string.
    data object_payload type string.
    data content_type type string.
endclass.



class zaws_s3_put_object implementation.
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

  method set_object_payload.
    me->object_payload = object_payload.
    _me = me.
  endmethod.

  method set_content_type.
    me->content_type = content_type.
    _me = me.
  endmethod.

  method execute.
    try.
        data(host) = |{ me->bucket_name }.s3.{ me->region }.amazonaws.com|.
        data(endpoint) = |https://{ host }/{ me->object_key }|.

        data(payload_hash) = zaws_sigv4_utilities=>get_hash( message = me->object_payload ).

        zaws_sigv4_utilities=>get_current_timestamp( importing amz_date  = data(amzdate)
                                                               datestamp = data(date_stamp) ).

        data(canonical_headers) = zaws_sigv4_utilities=>get_canonical_headers( value #(
          ( name = 'host' value = host )
          ( name = 'x-amz-date' value = amzdate )
          ( name = 'x-amz-content-sha256' value = payload_hash )
          ( name = 'content-type' value = me->content_type )
        ) ).

        data(signed_headers) = zaws_sigv4_utilities=>get_signed_headers( value #(
          ( name = 'host' )
          ( name = 'x-amz-date' )
          ( name = 'x-amz-content-sha256' )
          ( name = 'content-type' )
        ) ).

        data(canonical_request) = zaws_sigv4_utilities=>get_canonical_request(
          http_method           = 'PUT'
          canonical_uri         = |/{ me->object_key }|
          canonical_querystring = ''
          canonical_headers     = canonical_headers
          signed_headers        = signed_headers
          payload_hash          = payload_hash ).

        data(algorithm) = zaws_sigv4_utilities=>get_algorithm( ).

        data(credential_scope) = zaws_sigv4_utilities=>get_credential_scope( datestamp = date_stamp
                                                                             region    = me->region
                                                                             service   = 's3' ).

        data(string_to_sign) = zaws_sigv4_utilities=>get_string_to_sign(
          algorithm         = algorithm
          amz_date          = amzdate
          credential_scope  = credential_scope
          canonical_request = canonical_request ).

        data(signing_key) = zaws_sigv4_utilities=>get_signature_key( key          = me->secret_key
                                                                     datestamp    = date_stamp
                                                                     region_name  = region
                                                                     service_name = 's3' ).

        data(signature) = zaws_sigv4_utilities=>get_signature( signing_key    = signing_key
                                                               string_to_sign = string_to_sign ).

        data(credential) = zaws_sigv4_utilities=>get_credential( access_key       = me->access_key
                                                                 credential_scope = credential_scope ).

        data(authorization_header) = zaws_sigv4_utilities=>get_authorization_header(
          algorithm      = algorithm
          credential     = credential
          signature      = signature
          signed_headers = signed_headers ).

        cl_http_client=>create_by_url(
          exporting
            url    = |{ endpoint }|
          importing
            client = data(http_client)
        ).

        data(rest_client) = new cl_rest_http_client( io_http_client = http_client ).

        rest_client->if_rest_client~set_request_header( iv_name = 'host' iv_value = host ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-date' iv_value = amzdate ).
        rest_client->if_rest_client~set_request_header( iv_name = 'Authorization' iv_value = authorization_header ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-content-sha256' iv_value = payload_hash ).

        data(request) = rest_client->if_rest_client~create_request_entity( ).
        request->set_binary_data( cl_abap_hmac=>string_to_xstring( me->object_payload ) ).
        request->set_content_type( iv_media_type = content_type ).

        rest_client->if_rest_client~put( request ).
        data(response) = rest_client->if_rest_client~get_response_entity( ).
        response_headers = response->get_header_fields( ).

      catch cx_root into data(x_root).
        "Do something
    endtry.
  endmethod.

  method if_oo_adt_classrun~main.
    try.
        data(lo_s3) = new zaws_s3_put_object( ).
        lo_s3->set_access_key( '' ).
        lo_s3->set_secret_key( '' ).
        lo_s3->set_bucket_name( '' ).
        lo_s3->set_region( 'us-east-1' ).
        lo_s3->set_object_key( 'hello-world/welcome.txt' ).
        lo_s3->set_object_payload( 'Welcome to Amazon S3.' ).
        lo_s3->set_content_type( 'text/plain' ).

        data(response_headers) = lo_s3->execute( ).
        out->write( response_headers ).

      catch cx_root into data(x_root).
        out->write( x_root->get_text(  ) ).
        out->write( x_root->get_longtext(  ) ).
    endtry.
  endmethod.

endclass.
