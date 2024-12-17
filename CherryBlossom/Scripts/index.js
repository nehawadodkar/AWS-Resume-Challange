const counter = document.querySelector(".counter-number");

async function updateCounter() {
  try {
    // Fetch the response from the API
    let response = await fetch("https://zzz5e2pov4zc4574t2hwyqhn2m0tuhob.lambda-url.us-east-1.on.aws/");
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

    // Parse the JSON data
    let data = await response.json();
    
    // Check and display the updatedVisitCount
    if (data.updatedVisitCount) {
      counter.innerHTML = `Views: ${data.updatedVisitCount}`;
    } else {
      throw new Error("Unexpected response format");
    }
  } catch (error) {
    // Handle errors gracefully
    counter.innerHTML = "Couldn't read views";
    console.error("Error updating counter:", error);
  }
}

// Call the function to update the counter
updateCounter();
