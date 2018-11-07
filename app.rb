# frozen_string_literal: true

require 'bundler'
Bundler.require

# Create a Watir instance and scrap every pages
class Scrapper
  def initialize
    Dotenv.load
    @base_url = 'https://www.thehackingproject.org'
    @browser = Watir::Browser.new(:firefox)
    perform
  end
  
  def login(email, password)
    @browser.goto @base_url + '/login'
    login_email = @browser.text_field(id: 'user_email')
    login_password = @browser.text_field(id: 'user_password')
    login_email.set(email)
    login_password.set(password)
    login_password.send_keys(:enter)
  end
  
  def find_links
    links = []
    @browser.goto @base_url + '/dashboard/corrections'
    @browser.tds(class: 'text-right').each do |td|
      links << td.a.href
    end
    links
  end
  
  def scrap(links)
    data = []
    links.each do |link|
      @browser.goto link
      title = @browser.h3(class: 'title').text
      yes = @browser.elements(class: 'fa-check').count
      no = @browser.elements(class: 'fa-times').count
      data << { title: title, yes: yes.to_f, no: no.to_f }
    end
    data
  end
  
  def calculator(data)
    average_sum = []
    data.each do |hash|
      # Fix bug that add two full columns of 'no'
      if hash[:title] == 'Mettre son site en ligne 🚀 et formulaire'
        hash[:no] -= 30
      end
      grade = (hash[:yes] / (hash[:yes] + hash[:no]) * 4)
      average_sum << grade
      View.results(hash[:title], to_fixed(grade))
    end
    average = average_sum.reduce(:+) / data.length
    View.results('Average', to_fixed(average))
  end
  
  def to_fixed(float)
    format('%g', format('%.2f', float))
  end
  
  def perform
    login(ENV['THP_LOGIN'], ENV['THP_PASSWORD'])
    sleep(5)
    links = find_links
    data = scrap(links)
    calculator(data)
    @browser.close
  end
end

class Controller
  def self.grades
    Scrapper.new
  end
  
  def self.perform
    View.header
    grades
  end
end

# Display menu and results
class View
  def self.header
    puts '-------[THP Grades]-------'
  end
  
  def self.results(title, grade)
    puts "#{title}: #{grade}/4"
  end
end

Controller.perform
