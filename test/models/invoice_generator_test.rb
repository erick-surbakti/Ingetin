require "test_helper"

class InvoiceGeneratorTest < ActiveSupport::TestCase
  def generate(on:, tenants: Tenant.all)
    InvoiceGenerator.new(today: on, tenants: tenants).call
  end

  test "creates the invoice three days before the due date" do
    assert_empty generate(on: Date.new(2026, 11, 6)).select { |i| i.tenant == tenants(:rina) }

    created = generate(on: Date.new(2026, 11, 7)).select { |i| i.tenant == tenants(:rina) }
    assert_equal 1, created.size

    invoice = created.first
    assert_equal Date.new(2026, 11, 1), invoice.period
    assert_equal Date.new(2026, 11, 10), invoice.due_on
    assert_equal 1_500_000, invoice.amount
    assert_equal "Sewa Kos Melati kamar A1 November 2026", invoice.description
    assert invoice.unpaid?
    assert_equal 24, invoice.public_token.length
  end

  test "is idempotent" do
    first = generate(on: Date.new(2026, 11, 8))
    assert first.any?

    assert_no_difference -> { Invoice.count } do
      assert_empty generate(on: Date.new(2026, 11, 8))
      assert_empty generate(on: Date.new(2026, 11, 9))
    end
  end

  test "skips existing invoices and moved out tenants" do
    created = generate(on: Date.new(2026, 10, 28))

    assert_empty created.select { |i| i.tenant == tenants(:joko) && i.period == Date.new(2026, 10, 1) }
    assert_empty created.select { |i| i.tenant == tenants(:dewi_moved_out) }
  end

  test "creates next month's invoice inside the window at month end" do
    tenant = Tenant.create!(room: rooms(:melati_a3), name: "Sinta", phone: "081299998888",
      move_in_on: Date.new(2026, 9, 1), due_day: 1, created_at: Time.zone.local(2026, 11, 7, 9))

    assert_empty generate(on: Date.new(2026, 11, 7), tenants: Tenant.where(id: tenant))

    created = generate(on: Date.new(2026, 11, 28), tenants: Tenant.where(id: tenant))
    assert_equal [ Date.new(2026, 12, 1) ], created.map(&:due_on)
  end

  test "first invoice is for the due date after move-in" do
    tenant = Tenant.create!(room: rooms(:melati_a3), name: "Sinta", phone: "081299998888",
      move_in_on: Date.new(2026, 11, 10), created_at: Time.zone.local(2026, 11, 7, 9))
    assert_equal 10, tenant.due_day

    assert_empty generate(on: Date.new(2026, 11, 10), tenants: Tenant.where(id: tenant))
    assert_equal [ Date.new(2026, 12, 10) ], generate(on: Date.new(2026, 12, 7), tenants: Tenant.where(id: tenant)).map(&:due_on)
  end

  test "catches up a due date missed this month, but not before the tenant was recorded" do
    rina = tenants(:rina)
    created = generate(on: Date.new(2026, 11, 20), tenants: Tenant.where(id: rina))
    assert_equal [ Date.new(2026, 11, 10) ], created.map(&:due_on)

    late = Tenant.create!(room: rooms(:melati_a3), name: "Sinta", phone: "081299998888",
      move_in_on: Date.new(2026, 1, 5), due_day: 5, created_at: Time.zone.local(2026, 11, 20, 9))
    assert_empty generate(on: Date.new(2026, 11, 20), tenants: Tenant.where(id: late))
  end

  test "uses clamped due dates for short months" do
    joko = tenants(:joko)
    created = generate(on: Date.new(2027, 2, 25), tenants: Tenant.where(id: joko))
    assert_equal [ Date.new(2027, 2, 28) ], created.map(&:due_on)
  end

  test "scoped to one owner's tenants" do
    created = generate(on: Date.new(2026, 11, 28), tenants: users(:two).tenants)
    assert created.any?
    assert created.all? { |invoice| invoice.tenant == tenants(:joko) }
  end
end
