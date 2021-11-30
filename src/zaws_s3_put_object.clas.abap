class zaws_s3_put_object definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun.

  protected section.
  private section.
endclass.



class zaws_s3_put_object implementation.
  method if_oo_adt_classrun~main.
    try.
        data access_key type string value ''.
        data secret_key type string value ''.
        data bucket type string value ''.

        data region type string value 'us-east-1'.
        data message type string value 'Welcome to Amazon S3.'.
        data filename type string value 'testfile.txt'.
        data content_type type string value 'text/plain'.

        data(host) = |{ bucket }.s3.{ region }.amazonaws.com|.
        data(endpoint) = |https://{ host }/{ filename }|.

        data(payload_hash) = zaws_sigv4_utilities=>get_hash( message = message ).

        zaws_sigv4_utilities=>get_current_timestamp( importing amz_date  = data(amzdate)
                                                               datestamp = data(date_stamp) ).

        data(canonical_headers) = zaws_sigv4_utilities=>get_canonical_headers( value #(
          ( name = 'host' value = host )
          ( name = 'x-amz-date' value = amzdate )
          ( name = 'x-amz-content-sha256' value = payload_hash )
          ( name = 'content-type' value = content_type )
        ) ).

        data(signed_headers) = zaws_sigv4_utilities=>get_signed_headers( value #(
          ( name = 'host' )
          ( name = 'x-amz-date' )
          ( name = 'x-amz-content-sha256' )
          ( name = 'content-type' )
        ) ).

        data(canonical_request) = zaws_sigv4_utilities=>get_canonical_request(
          http_method           = 'PUT'
          canonical_uri         = |/{ filename }|
          canonical_querystring = ''
          canonical_headers     = canonical_headers
          signed_headers        = signed_headers
          payload_hash          = payload_hash ).

        data(algorithm) = zaws_sigv4_utilities=>get_algorithm( ).

        data(credential_scope) = zaws_sigv4_utilities=>get_credential_scope( datestamp = date_stamp
                                                                             region    = region
                                                                             service   = 's3' ).

        data(string_to_sign) = zaws_sigv4_utilities=>get_string_to_sign(
          algorithm         = algorithm
          amz_date          = amzdate
          credential_scope  = credential_scope
          canonical_request = canonical_request ).

        data(signing_key) = zaws_sigv4_utilities=>get_signature_key( key          = secret_key
                                                                     datestamp    = date_stamp
                                                                     region_name  = region
                                                                     service_name = 's3' ).

        data(signature) = zaws_sigv4_utilities=>get_signature( signing_key    = signing_key
                                                               string_to_sign = string_to_sign ).

        data(credential) = zaws_sigv4_utilities=>get_credential( access_key       = access_key
                                                                 credential_scope = credential_scope ).

        data(authorization_header) = zaws_sigv4_utilities=>get_authorization_header(
          algorithm      = algorithm
          credential     = credential
          signature      = signature
          signed_headers = signed_headers ).

         cl_http_client=>create_by_url(
          exporting url = |{ endpoint }|
          importing client = data(http_client)
        ).

        data(rest_client) = new cl_rest_http_client( io_http_client = http_client ).

        rest_client->if_rest_client~set_request_header( iv_name = 'host' iv_value = host ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-date' iv_value = amzdate ).
        rest_client->if_rest_client~set_request_header( iv_name = 'Authorization' iv_value = authorization_header ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-content-sha256' iv_value = payload_hash ).

        data(request) = rest_client->if_rest_client~create_request_entity( ).
        request->set_binary_data( cl_abap_hmac=>string_to_xstring( message ) ).
        request->set_content_type( iv_media_type = content_type ).

        rest_client->if_rest_client~put( request ).
        data(response) = rest_client->if_rest_client~get_response_entity( ).
        out->write( response->get_header_fields( ) ).

      catch cx_root into data(x_root).
        out->write( x_root->get_text(  ) ).
        out->write( x_root->get_longtext(  ) ).
    endtry.
  endmethod.

endclass.
