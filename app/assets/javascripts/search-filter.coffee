$(document).on 'keyup', '.search-filter', ->
  $target = $($(this).data('target'))
  filter = $(this).val()
  if filter == ""
    $target.find('tbody tr').show()
  else
    $target.find('tbody tr').each (index, element) ->
      if $(element).text().toLowerCase().indexOf(filter.toLowerCase()) != -1
        $(element).show()
      else
        $(element).hide()
