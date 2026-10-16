class InvoiceSummary
  attr_reader :invoices

  def initialize(invoices, today: Date.current)
    @invoices = invoices.to_a
    @today = today
  end

  def paid
    invoices.select(&:paid?)
  end

  def unpaid
    invoices.select(&:unpaid?)
  end

  def overdue
    unpaid.select { |invoice| invoice.overdue?(@today) }
  end

  def received_total
    paid.sum(&:amount)
  end

  def outstanding_total
    unpaid.sum(&:amount)
  end

  # Telat dulu, lalu belum bayar menurut jatuh tempo, lalu lunas.
  def sorted
    invoices.sort_by do |invoice|
      rank = if invoice.overdue?(@today) then 0 elsif invoice.unpaid? then 1 else 2 end
      [ rank, invoice.due_on, invoice.tenant.name ]
    end
  end
end
