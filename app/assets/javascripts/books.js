$(document).ready(function() {
  $('.x-get-book-info-from-google-books').on('click', function(e) {
    var isbn = $('.x-isbn').find('input').val();

    var request = $.ajax({
      url: "/google-isbn",
      method: "GET",
      data: { isbn : isbn },
      dataType: "json"
    });

    request.done(function( response ) {
      $('.x-published-date').find('input').val(response.publishedDate);
      $('.x-title').find('input').val(response.title);
      $('.x-page-count').find('input').val(response.pageCount);
    });
    request.fail(function( jqXHR, textStatus ) {
      alert( "Request failed: " + textStatus );
    });
    e.preventDefault();
  });
});

$(document).ready(function(){
  $('.x-autocomplete').each(function(i, obj) {
    $(obj).easyAutocomplete({
      url: '/api/v1/books/lookup',
      getValue: obj.id,
      list: {
        match: {
          enabled: true
        },
        onChooseEvent: function() {
          $('.x-autocomplete').each(function(i, obj) {
            var selectedData = $(obj).getSelectedItemData();
            if (selectedData === -1) { $(obj).val(''); }
          })
        }
      }
    });
  });
})
