# frozen_string_literal: true

# hltv_spider.rb
# rubcop: enable all
# rubocop:disable Metrics/MethodLength

require 'nokogiri'
require 'httparty'
require 'json'

# Este módulo implemente classes de Spiders para extrair dados do site HLTV
# https://www.hltv.org/
# O módulo HLTV é um módulo de nível superior que contém todas as classes de Spiders
#
module HLTV
  # Não vamos freezar esta constante mode ela pode ser alterada em caso de redirect
  # rubocop:disable Style/MutableConstant
  HEADER = {
    'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64; rv:103.0) Gecko/20100101 Firefox/103.0',
    'content-encoding' => 'br',
    'content-type' => 'text/html; charset=utf-8'
  }
  # rubocop:enable Style/MutableConstant
  BASE_URL = 'https://www.hltv.org'

  #
  # RankingSpider é uma classe de Spider que extrai dados do ranking de times
  # do site HLTV
  # Este spider irá coletar dados de todos os times do ranking em uma dada data
  # e irá armazenar os dados em um arquivo JSON
  #
  class RankingSpider
    def parse(url = nil)
      url ||= "#{BASE_URL}/ranking/teams"
      resp = get_url(url)

      # Caso contrário, inicializa um objeto Nokogiri com o HTML da resposta
      doc = Nokogiri::HTML(resp.body)

      # A estrutura de dados que vamos extrair é composta por times no ranking, que estão contidos
      # dentro de elementos <div> com a classe CSS 'ranking-header'.
      # Cada elemento 'ranking-header' contém informações importantes: o posicionamento do time
      # (span.position) e detalhes adicionais (div.relative).
      # Ao entrar em 'div.relative', encontramos:
      # - div.teamLine contendo informações do time, como nome (div.name) e pontos (div.points).
      # - jogadores do time armazenados em elementos <div> com a classe CSS 'playerLine'.
      #   Geralmente, cada div 'playerLine' possui 5 subelementos, incluindo div.rankingNicknames > span,
      #   que contém o nome do jogador.
      # Agora prosseguimos com a extração e manipulação dos dados conforme a estrutura mencionada.

      # Inicializa um array vazio para armazenar os times
      teams = []
      doc.css('div.ranking-header').each do |team|
        team_data = {}

        # captura a posição do time
        team_data[:position] = team.css('span.position').text

        relative_selec = team.css('div.relative')

        team_data[:name] = relative_selec.css('div.teamLine > span.name').text
        team_data[:points] = relative_selec.css('div.teamLine span.points').text

        team_data[:players] = relative_selec.css('div.playersLine > div.rankingNicknames').map do |p|
          p.css('span').text
        end

        clear_data! team_data
        teams << team_data
      end

      teams
    end

    def generate_json(filepath, url)
      data = parse(url)

      File.open(filepath, 'w') do |file|
        file.write(data.to_json)
      end
    end

    private

    def get_url(url)
      resp = HTTParty.get(url, headers: HEADER)
      raise ConnectionError, "Connection error: #{resp.code}" if resp.code != 200

      resp
    end

    def clear_data!(team_data)
      # Veja que points é da forma `(999 points)`. Vamos limpar isso e pegar apenas número
      team_data[:points] = team_data[:points].match(/[0-9]+/)[0].to_i

      # Ainda, a posição também é da forma #999. Vamos limpar isso
      team_data[:position] = team_data[:position].match(/[0-9]+/)[0].to_i
    end
  end

  class ConnectionError < StandardError
  end
end
