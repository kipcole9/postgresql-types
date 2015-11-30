require 'twitter_cldr'

class UnknownCurrency < ArgumentError; end

# Class for modelling money with currency code.  Note that since the Postgresql database
# already has a "money" type we use a composite type "currency" in the database.

class Money
  attr_accessor :currency, :amount
  cattr_accessor :default_currency
  @@default_currency = 'USD'
  
  delegate :to_i, :to_f, to: :amount
  
  def initialize(*args)
    if args.size == 2
      @currency = args.first.to_s
      @amount = args.second.to_d
    elsif args.size == 1 && args.first.is_a?(Hash)
      options = args.first
      @amount = options[:amount].to_d
      @currency = options[:currency].to_s
    elsif args.size == 1 && args.first.is_a?(String)
      match = args.first.match /([a-zA-Z]*)([+-]?\d*(\.\d+)?)/
      @currency = match[1]
      @amount = match[2].to_d
    elsif args.size == 1 && args.first.is_a?(Array)
      @currency = args.first.first.to_s
      @amount = args.first.second.to_d
    elsif args.size == 1
      @currency = nil
      @amount = args.first.to_d
    end 
    @currency.upcase!
    raise UnknownCurrency, "'#{@currency}' is not known currency." if @currency && !TwitterCldr::Shared::Currencies.currency_codes.include?(@currency)
  end
  
  def self.[](*args)
    new(*args)
  end
  
  def currency=(currency_code)
    return unless currency_code.present?
    raise UnknownCurrency, "'#{currency_code}' is not a known currency." unless TwitterCldr::Shared::Currencies.currency_codes.include?(currency_code)
    @currency = currency_code
  end
  
  def *(value)
    if value.is_a? Money
      Money.new(self.currency, self.amount * value.convert_to(self.currency).amount)      
    else
      Money.new(self.currency, self.amount * value)
    end
  end
  
  def /(value)
    if value.is_a? Money
      Money.new(self.currency, self.amount / value.convert_to(self.currency).amount)      
    else
      Money.new(self.currency, self.amount / value)
    end
  end
  
  def +(value)
    if value.is_a? Money
      Money.new(self.currency, self.amount + value.convert_to(self.currency).amount)      
    else
      Money.new(self.currency, self.amount + value)
    end
  end
  
  def -(value)
    if value.is_a? Money
      Money.new(self.currency, self.amount - value.convert_to(self.currency).amount)
    else
      Money.new(self.currency, self.amount - value)
    end
  end
  
  if defined?(ExchangeRate)
    def to_currency(to_currency_code, options = {})
      if self.currency == to_currency_code
        self
      else
        to_amount = ExchangeRate.convert(self.amount, self.currency, to_currency_code, options)
        Money.new(to_currency_code, to_amount)
      end
    end
  else
    def to_currency(to_currency_code, options = {})
      raise NotImpementedError, "Conversion can only occur if an ExchangeRate class is available"
    end
  end
  alias :convert_to :to_currency

  def to_s(options = {})
    locale = options.delete(:locale) || I18n.locale
    options = options.reverse_merge(currency: self.currency, use_cldr_symbol: true)
    currency = TwitterCldr::Localized::LocalizedNumber.new(self.amount || 0, locale).to_currency
    currency.to_s(options)
  end

  def to_db
    "(#{self.currency},#{self.amount})"
  end
  
  def as_json(*args)
    {currency: self.currency, amount: self.amount, formatted: to_s}
  end
  
  def inspect
    self.amount ? to_s : super
  end
  
end

module ActiveRecord
  module Type
    class Currency < ActiveModel::Type::Value # :nodoc:
      include ActiveModel::Type::Helpers::Mutable
      
      CURRENCY_DB_REGEXP = /(\w*),([+-]?\d+(\.\d+)?)/
      
      def self.as_json(options = {})
       {
         properties:  {
            amount: {
              type: :number, 
              description: I18n.t("schema.property.amount")
            },
            currency: {
              type: :string, 
              default: @@default_currency,
              description: I18n.t("schema.property.currency")
            },
            formatted: {
              type: :string, 
              readonly: true,
              description: I18n.t("schema.property.currency")
            }
          },
          required: [
            :amount
          ]
        }
      end

      def type
        :currency
      end
      
      def cast(value)
        Money.new(value)
      end

      def deserialize(value)
        return nil unless value.present?
        if matched = value.match(CURRENCY_DB_REGEXP)
          Money.new(matched[1], matched[2])
        else
          Money.new
        end
      end

      def serialize(value)
        value ? value.to_db : nil
      end
    end
  end
end


