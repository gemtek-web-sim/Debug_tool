// https://192.168.18.1/cgi/cgi_get?Objective=CSToken

const injector = angular.injector(["ng"]);
const $http = injector.get("$http");

let csrfToken = "";

function get_CSRF_token() {
  return new Promise((resolve, reject) => {
    $http
      .get("/cgi/cgi_get?Objective=CSToken")
      .then(function (responseok) {})
      .catch(function (response) {
        //get token alway returns 403
        if (response.status == 403 && response.headers("X-Csrf-Token")) {
          resolve(response.headers("X-Csrf-Token"));
        } else {
          reject("Fail to take CSRF Token");
        }
      });
  });
}

const hiddenHttpService = {
  GET: (url) => {
    return new Promise(async (resolve, reject) => {
      // first of all, tkae the csrf token (because we cannot use the angular config, we just have token)
      if (!csrfToken) {
        try {
          csrfToken = await get_CSRF_token();
        } catch (err) {
          reject(err);
        }
      }
      $http
        .get(url, {
          headers: {
            "X-Csrf-Token": csrfToken,
          },
        })
        .then(function (responseok) {
          console.log(
            "Request, Status, Response data, ",
            url,
            responseok.status
          );
          resolve(responseok.data);
        })
        .catch(function (response) {
          console.error("Status: ", response.status);
          reject("Fail to send request, Status: ", response.status);
        });
    });
  },
};
