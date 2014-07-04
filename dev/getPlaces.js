var GooglePlaces = require("googleplaces");
var googlePlaces = new GooglePlaces("AIzaSyB47_9zrIlKBFc11b7Yb7cSY0vdnzq1gJU", "json");
var parameters;

/**
 * Place search - https://developers.google.com/places/documentation/#PlaceSearchRequests
 */
parameters = {
  location:[48.889671, 2.368157],
  types:"",
  radius: 105000
};

googlePlaces.placeSearch(parameters, function (response) {
  for (var i in response.results) {
  	var obj = response.results[i];
  	console.log(obj.geometry.location.lat + "," + obj.geometry.location.lng + "," + obj.name.replace(/,/g, ''));
  }
  setTimeout(getPageResults(response.next_page_token), 3000);
});

function getPageResults(pToken){
	var param = { pagetoken: pToken } ;
  	googlePlaces.placeSearch(param, function (response) {
	  	for (var i in response.results) {
	  		var obj = response.results[i];
	  		console.log(obj.geometry.location.lat + "," + obj.geometry.location.lng + "," + obj.name.replace(/,/g, ''));
	  	}
  	});
}