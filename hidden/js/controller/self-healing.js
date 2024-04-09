const SELF_HEALING_CONTROLLER = {
  fill_front_end: () => {
    // Fetch content from sub.html and insert it into the div with id "content"
    fetch("hidden/self-healing.html")
      .then((response) => response.text())
      .then((html) => {
        document.getElementById("Content").innerHTML = html;
      })
      .catch((error) => console.error("Error fetching content:", error));
  },
  get_data: () => {
    return Promise.resolve("Not yet done");
  },
  set_data: () => {},
};
