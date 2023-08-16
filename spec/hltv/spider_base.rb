# frozen_string_literal: true
# rubocop: disable all

require 'rspec'
require './app/hltv_spider'

require 'byebug'

RSpec.describe HLTV::SpiderBase do
    spider = HLTV::SpiderBase.new
    describe '#get_url' do
        it 'returns an error when url was not found' do
            url = "#{HLTV::BASE_URL}/thisurldoesnotexists"
            expect { spider.get_url(url) }.to raise_error(HLTV::ConnectionError)
        end

        it 'returns 200 when a valid url is passed' do 
            resp = spider.get_url(HLTV::BASE_URL)
            expect(resp.code).to eq(200)
        end
    end

    describe '#search' do
        it 'returns a valid json when query has no result' do
            result = spider.search 'adikahjsdjklhaskljdhaskjld'
            expect(result.empty?).to eq(true)
        end

        it 'returns a valid json when query text is empty' do 
            result = spider.search ''
            expect(result.empty?).to eq(true)
        end

        it 'returns a valid json when valid  query text is passed' do 
            result = spider.search 'MIBR'
            expect(result[:team].nil?).to eq((false))
            expect(result[:article].nil?).to eq((false))
        end
        
        it 'returns a valid json when some query ONLY returns articles' do 
            result = spider.search 'Official:'
            expect(result[:team].nil?).to eq(true)
            expect(result[:player].nil?).to eq(true)
            expect(result[:article].nil?).to eq(false)
            expect(result[:article][0].instance_of? Hash).to eq(true)
        end
            

    end

end