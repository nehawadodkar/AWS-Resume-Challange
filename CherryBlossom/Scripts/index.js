const counter = document.querySelector(".counter-number");

async function updateCounter() {
  try {
    // 1. Call Lambda for visitor count (no change)
    let counterResponse = await fetch("https://your-lambda-function-url.amazonaws.com");
    if (!counterResponse.ok) throw new Error(`Lambda error! status: ${counterResponse.status}`);
    let counterData = await counterResponse.json();

    if (counterData.updatedVisitCount) {
      counter.innerHTML = `Views: ${counterData.updatedVisitCount}`;
    } else {
      throw new Error("Unexpected response format from Lambda");
    }

    // 2. Call ECS Analytics Service directly via Load Balancer DNS
    const analyticsPayload = {
      timestamp: new Date().toISOString(),
      user_agent: navigator.userAgent,
      referrer: document.referrer,
    };

    await fetch("http://analytics-alb-505390548.us-east-1.elb.amazonaws.com/log-visit", {
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
