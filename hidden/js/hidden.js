/**
 * ==========================
 *    Main menu interact
 * ==========================
 */
function home() {
  window.location.href = "hidden.html";
}

/**
 * @brief support to collasable the main menu
 */
function main_menu_toggle() {
  document.body.classList.toggle("mmc");
  document.body.classList.toggle("mme");
  const collapse = document.getElementById("main-navbar-collapse");
  collapse.classList.toggle("in");
}

/**
 * @brief hightlight when switch between tab
 * @param {*} name: name or ID of Button entity
 */
function switch_tab(name) {
  document.querySelectorAll(".menu-item").forEach((item) => {
    if (item.getAttribute("id") == name) {
      document
        .getElementById(item.getAttribute("id"))
        .classList.add("menuitem-highlight");
    } else {
      document
        .getElementById(item.getAttribute("id"))
        .classList.remove("menuitem-highlight");
    }
  });

  load_page(get_name(), get_controller());
}

/**
 * @brief: show the
 * @param {*} message
 */
function alertFail(message) {
  const failAlert = document.getElementById("failAlert");

  failAlert.classList.remove("ng-hide");
  document.querySelector("#failAlert p").textContent = message;

  // button close handler
  const closeButton = document.querySelector("#failAlert a");
  closeButton.removeEventListener("click", close_fail_alert);
  closeButton.addEventListener("click", close_fail_alert);
}

// Function to close the failAlert
function close_fail_alert() {
  document.getElementById("failAlert").classList.add("ng-hide");
}

/**
 * ==========================
 *        Load function
 * ==========================
 */
function load_header(name) {
  document.getElementById("Header").textContent = name;
  document.getElementById("Sub-header").textContent =
    MENU_INFO[name].description;
}

/**
 * @brief Load the whole page (contains data)
 * @param {*} name
 * @param {*} controller
 */
function load_page(name, controller) {
  console.log(`\n\nLoad page ... ${name}`);
  // change the header & decription (sub header)
  load_header(name);

  // Fill data
  $("#ajaxLoaderSection").show();
  controller
    .get_data()
    .then((data) => {
      document.getElementById("Content").innerHTML = ""; // reset content
      // Fill front end of corresponding tab
      controller.fill_front_end(data);
      $("#ajaxLoaderSection").hide();
    })
    .catch((err) => {
      alertFail("Get data going fail !!!");
      console.error("Get data going fail. ", err);
      $("#ajaxLoaderSection").hide();
    });
}

/**
 * ============================
 *    Get attribute from FE
 * ============================
 */
/**
 *
 * @returns controller of current tab
 */
function get_controller() {
  return MENU_INFO[
    document.querySelector(".menuitem-highlight").getAttribute("id")
  ].controller;
}

/**
 *
 * @returns ID name of current tab
 */
function get_name() {
  return document.querySelector(".menuitem-highlight").getAttribute("id");
}
