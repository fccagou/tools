

function RemoteDisplay( container_id ) {

    $.getJSON('/remote/list', function ( data ) {
       var items = [];

        $.each( data , function (site) {
        // TODO: ajouter un div pour le site
              items.push('<div class="col justify-content-center"><div class="container site"><h1>' + site + '</h1></div>');
            items.push('<div class="col">')
            items.push('<div class="card border-dark mb-3" >')
            items.push('<div class="card-header">' + site +'</div>')
            items.push('<div class="card-body text-dark">')
            items.push('<div class="row">');

            $.each( data[site] , function (domain, val) {

                items.push('<div class="col"><p><img src="/computer.png" /> ' + domain + '</p><div class="btn-group-vertical">');

                $.each( val , function(group, remote_host_list ) {

                    $.each( remote_host_list, function(h) {
                        remote_host=remote_host_list[h]
                        var url = '/remote/' + site + '/' + domain + '/' + group + '/' + remote_host;
                        items.push('<a href="' + url +'" class="btn btn-' + group + '" role="button" data-toggle="tooltip" data-placement="top" title=" Connexion à '+domain+'">'+remote_host+'</span></a>');
                        //<span class="badge badge-secondary">'+remote_host+'</span></a>');
                    });

                });

                items.push('</div></div>');

            });
              items.push('</div></div>');
                items.push('</div></div></div></div>');
        });
        $(container_id).html(items.join(""));
    });
}

