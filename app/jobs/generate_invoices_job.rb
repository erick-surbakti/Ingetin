class GenerateInvoicesJob < ApplicationJob
  queue_as :default

  def perform
    InvoiceGenerator.new.call
  end
end
