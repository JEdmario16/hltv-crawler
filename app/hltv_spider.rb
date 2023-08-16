# frozen_string_literal: true

# hltv_spider.rb
# rubcop: enable all
# rubocop:disable Metrics/MethodLength

require 'nokogiri'
require 'httparty'
require 'json'
require 'date'

require 'byebug'
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

  # Classe de base para as outras spiders
  # Define métodos genéricos úteis em cada um dos spiders
  class SpiderBase
    def get_url(url)
      resp = HTTParty.get(url, headers: HEADER)
      raise ConnectionError, "Connection error: #{resp.code}" if resp.code != 200

      resp
    end

    def generate_json(filepath, url = nil, **kwargs)
      # Esperamos que um método `parse` seja definido para
      # a classe que herdar esta aqui
      data = parse(url, **kwargs)

      File.open(filepath, 'w') do |file|
        file.write(data.to_json)
      end
    end

    # Este método irá usar o search da hltv e fazer uma busca pela
    # query_string passada
    def search(query)
      url = "#{BASE_URL}/search?query=#{query}"
      resp = get_url(url)
      doc = Nokogiri::HTML5(resp)
      # A rota de busca retorna resultados separados por categorias.
      # As categorias são: Player, Team, Event e Article
      # Os resultados de categorias estão armazenados na seguinte estrutura:
      # tr > td.table-header armazena o nome da categoria
      # as td's irmãs do header armazena os resultados. Elas tem uma classe=''

      # Este seletor armazena o conteúdo do resultado
      # Como podem existir outras tables na página, vou usar
      # este seletor um pouco mais específico.

      search_result = {}

      table_bodies = doc.css('div.search > table > tbody')

      table_bodies.each do |tbody|
        tbody_results = tbody.css('tr')
        header = tbody_results.css('td.table-header').first.text.downcase.to_sym
        tbody_results.shift # Remove o header
        search_result[header] = []
        tbody_results.each do |result|
          if header == :article
            article = {
              title: result.css('td > a').first.text,
              date: result.css('td.text-center > span').first.text,
              author: result.css('td.text-center > a').text
            }
            search_result[header] << article
          else
            search_result[header] << result.css('td > a').text
          end
        end
      end

      search_result
    end

    def to_s
      "<Spider #{self.class}>"
    end

    def inspect
      to_s
    end
  end

  #
  # RankingSpider é uma classe de Spider que extrai dados do ranking de times
  # do site HLTV
  # Este spider irá coletar dados de todos os times do ranking em uma dada data
  # e irá armazenar os dados em um arquivo JSON
  #
  class RankingSpider < SpiderBase
    ALLOWED_REGIONS = [
      'North America', 'Argentina', 'Brazil', 'Belarus',
      'Czech Republic', 'Denmark', 'Finland', 'France', 'Germany',
      'Hungary', 'Kazakhstan', 'Poland', 'Portugal', 'Russia',
      'Sweden', 'Ukraine', 'United Kingdom', 'Asia', 'Mongolia',
      'Australia', 'Noth America', 'South America', 'Europe', 'Oceania'
    ].freeze

    def parse(url = nil, **kwargs)
      if url.nil?
        url = if kwargs.empty?
                "#{BASE_URL}/ranking/teams/"
              else
                generate_url(date: kwargs[:date], region: kwargs[:region])
              end
      end
      # Caso seja passada uma url
      resp = get_url(url)
      doc = Nokogiri::HTML5(resp.body)

      # Inicializa um array vazio para armazenar os times
      teams = []
      doc.css('div.ranking-header').each do |team|
        team_data = proccess team
        teams << team_data
      end

      teams
    end

    def proccess(team)
      #
      # A estrutura de dados que vamos extrair é composta por times no ranking, que estão contidos
      # dentro de elementos <div> com a classe CSS 'ranking-header'.
      # Cada elemento 'ranking-header' contém informações importantes: o posicionamento do time
      # (span.position) e detalhes adicionais (div.relative).
      # Ao entrar em 'div.relative', encontramos:
      # - div.teamLine contendo informações do time, como nome (div.name) e pontos (div.points).
      # - jogadores do time armazenados em elementos <div> com a classe CSS 'playerLine'.
      #   Geralmente, cada div 'playerLine' possui 5 subelementos, incluindo div.rankingNicknames > span,
      #   que contém o nome do jogador.
      # Para este método, vamos considerar que a div passada será 'div.ranking-header'
      #

      team = team.instance_of?(Nokogiri::HTML5) ? team : Nokogiri::HTML5(team)
      raise('Team div must be an "ranking-header" class') if team.css('div.ranking-header').empty?

      team_data = {}

      # captura a posição do time
      team_data[:position] = team.css('span.position').text

      relative_selec = team.css('div.relative')

      team_data[:name] = relative_selec.css('div.teamLine > span.name').text or nil
      team_data[:points] = relative_selec.css('div.teamLine span.points').text or nil

      team_data[:players] = relative_selec.css('div.playersLine > div.rankingNicknames').map do |p|
        p.css('span').text or nil
      end
      clear_data! team_data
      team_data
    end

    private

    def generate_url(**kwargs)
      raise('invalid Region') unless !kwargs[:region].nil? && !(kwargs[:region] in ALLOWED_REGIONS)

      # Esperamos que date seja da forma yyyy-mm-dd
      # Caso a data passado for uma string, converte para um Date object
      date = Date.strptime(kwargs[:date], '%Y-%m-%d') if kwargs[:date].instance_of?(String)

      # Pega a Segunda-feria anterior mais próxima
      date -= 1 until date.monday?

      # Converte a data para obter o nome do mês
      date = date.strftime('%Y-%B-%d')
      year, month, day = date.split('-')

      # Por fim, geramos uma nova url
      # É sempre muito estranho esses retornos implícitos btw
      "#{BASE_URL}/ranking/teams/#{year}/#{month.downcase}/#{day}"
    end

    def clear_data!(team_data)
      matched = team_data[:points].match(/[0-9]+/)
      team_data[:points] = !matched.nil? ? matched[0].to_i : nil

      matched = team_data[:position].match(/[0-9]+/)
      team_data[:position] = !matched.nil? ? matched[0].to_i : nil

      team_data.each { |k, v| team_data[k] = nil if v == '' }
    end
  end

  class TeamSpider
  end

  class ConnectionError < StandardError
  end
end
