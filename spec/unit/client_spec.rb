require 'spec_helper'

module BrowserMob
  module Proxy

    DOMAIN = 'example.com'

    describe Client do
      let(:resource)      { double(RestClient::Resource) }
      let(:client)        { Client.new(resource, "localhost", 9091) }

      before do
        {
          "har"                  => double("resource[har]"),
          "har/pageRef"          => double("resource[har/pageRef]"),
          "whitelist"            => double("resource[whitelist]"),
          "blacklist"            => double("resource[blacklist]"),
          "limit"                => double("resource[limit]"),
          "headers"              => double("resource[headers]"),
          "auth/basic/#{DOMAIN}" => double("resource[auth/basic/#{DOMAIN}]")
        }.each do |path, mock|
          resource.stub(:[]).with(path).and_return(mock)
        end
      end

      it "creates a named har" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return('')

        client.new_har("foo").should be_nil
      end

      it "creates a new har with no name" do
        resource['har'].should_receive(:put).
                        with({}).
                        and_return('')

        client.new_har.should be_nil
      end

      it "returns the previous archive if one exists" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo").
                        and_return(fixture("google.har"))

        client.new_har("foo").should be_kind_of(HAR::Archive)
      end

      it "turns on header capture when given a name" do
        resource['har'].should_receive(:put).
                        with(:initialPageRef => "foo", :captureHeaders => true).
                        and_return('')

        client.new_har("foo", :capture_headers => true).should be_nil
      end

      it "turns on header capture when not given a name" do
        resource['har'].should_receive(:put).
                        with(:captureHeaders => true).
                        and_return('')

        client.new_har(:capture_headers => true).should be_nil
      end

      it "gets the current har" do
        resource['har'].should_receive(:get).
                        and_return(fixture("google.har"))

        client.har.should be_kind_of(HAR::Archive)
      end

      it "creates a new page" do
        resource['har/pageRef'].should_receive(:put).
                                with :pageRef => "foo"

        client.new_page "foo"
      end

      it "sets the blacklist" do
        resource['blacklist'].should_receive(:put).
                              with(:regex => "http://example.com", :status => 401)

        client.blacklist(%r[http://example.com], 401)
      end

      it "sets the whitelist" do
        resource['whitelist'].should_receive(:put).
                              with(:regex => "http://example.com", :status => 401)

        client.whitelist(%r[http://example.com], 401)
      end

      it "sets the :downstream_kbps limit" do
        resource['limit'].should_receive(:put).
                          with('downstreamKbps' => 100)

        client.limit(:downstream_kbps => 100)
      end

      it "sets the :upstream_kbps limit" do
        resource['limit'].should_receive(:put).
                          with('upstreamKbps' => 100)

        client.limit(:upstream_kbps => 100)
      end

      it "sets the :latency limit" do
        resource['limit'].should_receive(:put).
                          with('latency' => 100)

        client.limit(:latency => 100)
      end

      it "sets all limits" do
        resource['limit'].should_receive(:put).
                          with('latency' => 100, 'downstreamKbps' => 200, 'upstreamKbps' => 300)

        client.limit(:latency => 100, :downstream_kbps => 200, :upstream_kbps => 300)
      end

      it "raises ArgumentError on invalid options" do
        lambda { client.limit(:foo => 1) }.should raise_error(ArgumentError)
        lambda { client.limit({})        }.should raise_error(ArgumentError)
      end

      it "sets headers" do
        resource['headers'].should_receive(:post).with('{"foo":"bar"}', :content_type => "application/json")

        client.headers(:foo => "bar")
      end

      it 'sets basic authentication' do
        user, password = 'user', 'pass'
        resource["auth/basic/#{DOMAIN}"].should_receive(:post).with(%({"username":"#{user}","password":"#{password}"}), :content_type => "application/json")

        client.basic_authentication(DOMAIN, user, password)
      end

      context "#selenium_proxy" do
        it "defaults to HTTP proxy only" do
          proxy = client.selenium_proxy

          proxy.http.should == "#{client.host}:#{client.port}"
          proxy.ssl.should be_nil
          proxy.ftp.should be_nil
        end

        it "allows multiple protocols" do
          proxy = client.selenium_proxy(:http, :ssl)

          proxy.http.should == "#{client.host}:#{client.port}"
          proxy.ssl.should == "#{client.host}:#{client.port}"
          proxy.ftp.should be_nil
        end

        it "allows disabling HTTP proxy" do
          proxy = client.selenium_proxy(:ssl)

          proxy.ssl.should == "#{client.host}:#{client.port}"
          proxy.http.should be_nil
          proxy.ftp.should be_nil
        end

        it "raises an error when a bad protocol is used" do
          lambda {
            client.selenium_proxy(:htp)
          }.should raise_error
        end
      end
    end

  end
end
