# frozen_string_literal: true
# rubocop: disable all

require 'rspec'
require './app/hltv_spider'

require 'byebug'

RSpec.describe HLTV::RankingSpider do
  describe '#parse' do
    context 'when response is 200' do
      it 'returns a json object' do
        url = 'https://www.hltv.org/ranking/teams/2021/july/19'
        spider = HLTV::RankingSpider.new
        parsed_data = spider.parse(url)
        expect(parsed_data).to be_a(Array)
        expect(parsed_data.empty?).to be false
      end

      it 'returns a valid results for the first position' do
        # nota: Como o rank da HLTV é imutável, podemos usar dados que foram obtidos anteriormente
        # para checar se o crawler continua ok
        # Aqui estamos testando especificamente a posição 1 pois o código html desta posição é um pouco diferente
        # ( neste caso, a hlv sempre mostra a foto de perfil da lineup)
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
        spider = HLTV::RankingSpider.new
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
      it  'returns a valid json when no url is provided' do
        spider = HLTV::RankingSpider.new
        parsed_data = spider.parse()

        expect(parsed_data.empty?).to eq(false)
      end
      it 'returns a valid json when valid date and regions is provided' do
        spider = HLTV::RankingSpider.new
        parsed_data = spider.parse(date:'2023-01-01', region: 'Brazil')
        
        expect(parsed_data).to be_a(Array)
        expect(parsed_data.empty?).to be false
      end

      it 'returns a valid json when valid date and no region is provided' do 
        spider = HLTV::RankingSpider.new
        parsed_data = spider.parse(date:'2023-03-03', region: '')

        expect(parsed_data).to be_a(Array)
        expect(parsed_data.empty?).to be false
      end

      it 'returns a valid json when no url, region and date is provided' do
        spider = HLTV::RankingSpider.new
        parsed_data = spider.parse()

        expect(parsed_data).to be_a(Array)
        expect(parsed_data.empty?).to be false
      end
    end

    context 'when response is not 200' do
      it 'raises a ConnectionError' do
        url = 'https://www.hltv.org/ranking/teams/2021/july/18'
        spider = HLTV::RankingSpider.new
        expect { spider.parse(url) }.to raise_error(HLTV::ConnectionError)
      end
    end

    context 'when generate a json file' do 
      it 'generate a json file when a valid url is provided' do
        url = 'https://www.hltv.org/ranking/teams/2021/july/19'
        filepath = 't.json'
        spider = HLTV::RankingSpider.new
        spider.generate_json(filepath, url)

        expect(File.exist?(filepath)).to eq(true)

        # Caso o arquivo exista, vamos deletá-lo, pois criamos ele durante o teste
        File.delete(filepath)
        expect(File.exist?(filepath)).to eq(false)
      end
    end

    context 'when processing a teamDiv' do
      it 'sets to nil when the given field is blank' do
        my_div = "<div class='ranking-header'><span class='position'></span></div>"
        spider = HLTV::RankingSpider.new
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

    context 'when generating an url' do
      it 'Raises an error when invalid region is passed to' do
      end
    end
  end
end
