class Invoice::DataPresenter
  attr_reader :invoice
  delegate :data, :date, to: :invoice

  FINALIZED_NON_SUCCESSFUL_STATES = %w(canceled returned).freeze

  extend Invoice::DataPresenterAttributes

  attributes :included_tax_total, :additional_tax_total, :state, :total, :payment_total,
             :currency
  attributes :number, :note, :special_instructions, prefix: :order
  attributes_with_presenter :order_cycle, :distributor, :customer, :ship_address,
                            :shipping_method, :bill_address

  array_attribute :sorted_line_items, class_name: 'LineItem'
  array_attribute :all_eligible_adjustments, class_name: 'Adjustment'
  array_attribute :payments, class_name: 'Payment'

  relevant_attributes :order_note, :distributor, :sorted_line_items

  def initialize(invoice)
    @invoice = invoice
  end
  
  def has_taxes_included
    included_tax_total > 0
  end

  def total_tax
    additional_tax_total + included_tax_total
  end

  def order_completed_at
    return nil if data[:completed_at].blank?

    Time.zone.parse(data[:completed_at])
  end

  def checkout_adjustments(exclude: [], reject_zero_amount: true)
    adjustments = all_eligible_adjustments

    if exclude.include? :line_item
      adjustments.reject! { |a|
        a.adjustable_type == 'Spree::LineItem'
      }
    end

    if reject_zero_amount
      adjustments.reject! { |a| a.amount == 0 }
    end

    adjustments
  end

  def invoice_date
    date
  end

  def paid?
    data[:payment_state] == 'paid' || data[:payment_state] == 'credit_owed'
  end

  def outstanding_balance?
    !new_outstanding_balance.zero?
  end

  def new_outstanding_balance
    if state.in?(FINALIZED_NON_SUCCESSFUL_STATES)
      -payment_total
    else
      total - payment_total
    end
  end

  def outstanding_balance_label
    new_outstanding_balance.negative? ? I18n.t(:credit_owed) : I18n.t(:balance_due)
  end

  def last_payment
    payments.max_by(&:created_at)
  end

  def last_payment_method
    last_payment&.payment_method
  end

  def display_outstanding_balance
    Spree::Money.new(new_outstanding_balance, currency: currency)
  end

  def display_checkout_tax_total
    Spree::Money.new(total_tax, currency: currency)
  end

  def display_checkout_total_less_tax
    Spree::Money.new(total - total_tax, currency: currency)
  end

  def display_total
    Spree::Money.new(total, currency: currency)
  end
end
