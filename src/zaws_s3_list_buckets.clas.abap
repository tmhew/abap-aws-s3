class zaws_s3_list_buckets definition
  public
  final
  create public .

  public section.
    types: begin of bucket,
             creation_date type string,
             name          type string,
           end of bucket.

    types: begin of owner,
             id           type string,
             display_name type string,
           end of owner.

    types: begin of response_payload,
             owner   type owner,
             buckets type table of bucket with key name,
           end of response_payload.

    interfaces if_oo_adt_classrun.

    class-methods parse_response_payload importing value(payload)        type string
                                         returning value(parsed_payload) type response_payload.

    methods set_region importing region     type string
                       returning value(_me) type ref to zaws_s3_list_buckets.

    methods set_host importing host       type string
                     returning value(_me) type ref to zaws_s3_list_buckets.

    methods set_service_endpoint importing s3_service_endpoint type string
                                 returning value(_me)          type ref to zaws_s3_list_buckets.

    methods set_access_key importing access_key type string
                           returning value(_me) type ref to zaws_s3_list_buckets.

    methods set_secret_key importing secret_key type string
                           returning value(_me) type ref to zaws_s3_list_buckets.

    methods execute exporting status_code type string
                              payload type string.
  protected section.
  private section.
    data region type string.
    data host type string.
    data service_endpoint type string.
    data access_key type string.
    data secret_key type string.
endclass.



class zaws_s3_list_buckets implementation.
  method parse_response_payload.
    try.
        replace first occurrence of |<?xml version="1.0" encoding="UTF-8"?>{ cl_abap_char_utilities=>newline }| in payload with ''.
        data(bin_payload) = cl_abap_hmac=>string_to_xstring( payload ).

        call transformation zaws_s3_list_buckets_response
          source xml bin_payload
          result payload = parsed_payload.
      catch cx_root into data(x_root).
    endtry.
  endmethod.

  method set_region.
    me->region = region.
    _me = me.
  endmethod.

  method set_host.
    me->host = host.
    _me = me.
  endmethod.

  method set_service_endpoint.
    me->service_endpoint = s3_service_endpoint.
    _me = me.
  endmethod.

  method set_access_key.
    me->access_key = access_key.
    _me = me.
  endmethod.

  method set_secret_key.
    me->secret_key = secret_key.
    _me = me.
  endmethod.

  method execute.
    try.
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

        data(canonical_request) = zaws_sigv4_utilities=>get_canonical_request(
          http_method           = 'GET'
          canonical_uri         = '/'
          canonical_querystring = ''
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

        cl_http_client=>create_by_url( exporting url    = service_endpoint
                                       importing client = data(http_client) ).
        data(rest_client) = new cl_rest_http_client( io_http_client = http_client ).

        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-date' iv_value = amzdate ).
        rest_client->if_rest_client~set_request_header( iv_name = 'Authorization' iv_value = authorization_header ).
        rest_client->if_rest_client~set_request_header( iv_name = 'x-amz-content-sha256' iv_value = payload_hash ).

        rest_client->if_rest_client~get( ).
        data(response) = rest_client->if_rest_client~get_response_entity( ).

        status_code = response->get_header_field( '~status_code' ).
        payload = response->get_string_data(  ).

      catch cx_root into data(x_root).
        "Do something?
    endtry.
  endmethod.

  method if_oo_adt_classrun~main.
    data(lo_s3) = new zaws_s3_list_buckets( ).
    lo_s3->set_access_key( '' ).
    lo_s3->set_secret_key( '' ).
    lo_s3->set_host( 's3.us-east-1.amazonaws.com' ).
    lo_s3->set_region( 'us-east-1' ).
    lo_s3->set_service_endpoint( 'https://s3.us-east-1.amazonaws.com' ).

    lo_s3->execute( importing status_code = data(status_code)
                              payload = data(payload) ).

    out->write( status_code ).

    if status_code = '200'.
        data(bucket_list) = zaws_s3_list_buckets=>parse_response_payload( payload ).
        out->write( bucket_list-buckets ).
    else.
        out->write( payload ).
    endif.

  endmethod.

endclass.
