

function RemoteDisplay( container_id ) {

    $.getJSON('/remote/list', function ( data ) {

       var items = [];

        $.each( data , function (site) {

            items.push('<div class="col justify-content-center">');
            items.push('<div class="col">')
            items.push('<div class="card border-dark mb-3" >')
            items.push('<div class="card-header"><img src="/computer.png" />' + site +'</div>')
            items.push('<div class="card-body text-dark">')
            items.push('<div class="row">');

            $.each( data[site] , function (domain, val) {

                items.push('<div class="col align-self-start remote-domain"><p class="remote-domain">' + domain + '</p><div class="btn-group-vertical">');

                $.each( val , function(group, remote_host_list ) {

                    $.each( remote_host_list, function(h) {

                        remote_host=remote_host_list[h]
                        var url = '/remote/' + site + '/' + domain + '/' + group + '/' + remote_host;
                        items.push('<a href="' + url +'" class="btn btn-' + group + '" role="button" data-toggle="tooltip" data-placement="top" title=" Connexion à '+domain+'">'+remote_host+'</span></a>');

                    }); // host_list

                }); // group

                items.push('</div></div>');

            }); // domain

            items.push('</div></div>');
            items.push('</div></div></div></div>');

        }); // site

        $(container_id).html(items.join(""));

    }); // data

}


function CreateNavBar( container_id ) {

    $.getJSON('/conf/menu', function ( data ) {
        var items = [];
        $.each( data, function ( title ) {
            items.push('<li class="nav-item"><a class="nav-link" href="'+data[title]+'">'+title+'</a></li>');
        });

        $(container_id).html(items.join(""));
    });
}

