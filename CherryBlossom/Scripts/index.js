const counter = document.querySelector(".counter-number");

async function updateCounter() {
  try {
    const config = await import('./config.js');
    console.log("Lambda Function URL:", config.FUNCTION_URL);

    // 1. Call Lambda for visitor counter
    let response = await fetch(config.FUNCTION_URL);
    if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

    let data = await response.json();

    if (data.updatedVisitCount) {
      counter.innerHTML = `Views: ${data.updatedVisitCount}`;
    } else {
      throw new Error("Unexpected response format from Lambda");
    }

    // 2. Send analytics data to ECS (hardcoded URL)
    const analyticsPayload = {
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent,
      referrer: document.referrer,
      // Leave out IP – backend will derive it if needed
    };

    console.log("Sending analytics data:", analyticsPayload);

    await fetch("https://analytics.neha-wadodkar.com/log-visit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(analyticsPayload)
    });

  } catch (error) {
    counter.innerHTML = "Couldn't read views";
    console.error("Error updating counter or logging analytics:", error);
  }
}

updateCounter();