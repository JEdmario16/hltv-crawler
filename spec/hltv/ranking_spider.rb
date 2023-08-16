# frozen_string_literal: true
# rubocop: disable all

require 'rspec'
require './app/hltv_spider'

require 'byebug'

RSpec.describe HLTV::RankingSpider do
  spider = HLTV::RankingSpider.new
  describe '#parse' do
    it 'returns a json object when valid url is provided' do
      url = 'https://www.hltv.org/ranking/teams/2021/july/19'
      parsed_data = spider.parse(url)
      expect(parsed_data).to be_a(Array)
      expect(parsed_data.empty?).to be false
    end

    it 'returns a valid results for the first position' do
      data = {
        "position": 1,
        "name": 'Natus Vincere',
        "points": 965,
        "players": %w[
          s1mple
          electroNic
          Boombl4
          Perfecto
          b1t
        ]
      }
      url = 'https://www.hltv.org/ranking/teams/2021/july/19'
      parsed_data = spider.parse(url)
      expect(parsed_data[0]).to eq(data)
    end

    it 'returns a valid results for the 11th position' do
      # Nota: Como o rank do HLTV é imutável, podemos usar os dados obtidos anteriormente.
      # Não existe nenhum motivo especial para testarmos a 11th posição;

      data = {
        "position": 11,
        "name": 'MOUZ',
        "points": 246,
        "players": %w[
          dexter
          frozen
          acoR
          ropz
          Bymas
        ]
      }
      url = 'https://www.hltv.org/ranking/teams/2021/july/19'
      spider = HLTV::RankingSpider.new
      parsed_data = spider.parse(url)

      expect(parsed_data[10]).to eq(data)
    end

    it  'returns a valid json when no params is provided' do
      parsed_data = spider.parse()

      expect(parsed_data.empty?).to eq(false)
      expect(parsed_data).to be_a(Array)
    end

    it 'returns a valid json when valid date and regions is provided' do
      parsed_data = spider.parse(date:'2023-01-01', region: 'Brazil')
      
      expect(parsed_data).to be_a(Array)
      expect(parsed_data.empty?).to be false
    end

    it 'returns a valid json when valid date and no region is provided' do 
      parsed_data = spider.parse(date:'2023-03-03', region: '')

      expect(parsed_data).to be_a(Array)
      expect(parsed_data.empty?).to be false
    end
  end

  describe '#generate_json' do
    it 'generate a json file when a valid url is provided' do
      url = 'https://www.hltv.org/ranking/teams/2021/july/19'
      filepath = 't.json'

      spider.generate_json(filepath, url)
      expect(File.exist?(filepath)).to eq(true)

      # Caso o arquivo exista, vamos deletá-lo, pois criamos ele durante o teste
      File.delete(filepath)
      expect(File.exist?(filepath)).to eq(false)
    end
  end
  describe '#proccess' do
    it 'sets to nil when the given field is blank' do
      my_div = "<div class='ranking-header'><span class='position'></span></div>"
      result = spider.proccess(my_div)
      expected = {
        :points => nil,
        :name => nil,
        :players => [],
        :position => nil,
      }

      expect(result).to eq(expected)
    end
  end
  describe '#generate_url' do
    it 'Raises an error when invalid region is passed to' do

    end
  end
end
