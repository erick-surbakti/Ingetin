module ApplicationHelper
  def nav_link(label, path)
    active = path == root_path ? current_page?(root_path) : request.path.start_with?(path)
    classes = active ? "bg-brand-50 text-brand-700" : "text-stone-600 hover:bg-stone-100"

    link_to label, path, class: "shrink-0 rounded-md px-3 py-1.5 #{classes}", aria: { current: (active ? "page" : nil) }
  end

  def rupiah(amount)
    number_to_currency(amount)
  end

  def phone_display(number)
    PhoneNumber.display(number)
  end
end
