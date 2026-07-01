// --- グローバル変数 ---
float stamina = 100;
float maxStamina = 100;
int stepCount = 0;
float walkCycle = 0; 

// --- 1. 階段の設定 ---
int numSteps = 20; 
float stepW = 90;  
float stepH = 50;  // 蹴上げを「1」とする
float[] stepsX = new float[numSteps];
float[] stepsY = new float[numSteps];

float offsetX, offsetY;

void setup() {
  size(800, 800); 
  for (int i = 0; i < numSteps; i++) {
    stepsX[i] = i * stepW; 
    stepsY[i] = height - (i * stepH);
  }
  strokeCap(ROUND);
  strokeJoin(ROUND);
}

void draw() {
  background(255); 
  
  // --- 2. 疑似触覚：スピードとスタミナ ---
  float staminaRatio = stamina / maxStamina;
  float fatigue = 1.0 - staminaRatio; // 疲労度 (0.0〜1.0)
  
  float currentWalkSpeed = 0.03 * pow(staminaRatio, 0.6); 
  
  if (keyPressed && keyCode == UP && stamina > 0.1) {
    walkCycle += currentWalkSpeed; 
    stamina = max(stamina - 0.15, 0); 
  } else {
    stamina = min(stamina + 0.3, maxStamina); 
  }
  
  if (stamina < 0.1) currentWalkSpeed = 0;

  // --- 3. 座標計算 ---
  int currentStepIndex = floor(walkCycle); 
  stepCount = currentStepIndex;
  float p = walkCycle - currentStepIndex; 

  float bodyCurve = pow(p, 2.5);
  float playerX = currentStepIndex * stepW + (bodyCurve * stepW);
  float playerY = height - (currentStepIndex * stepH) - (bodyCurve * stepH);
  
  offsetX = width / 2 - playerX - 150;
  offsetY = height / 2 - playerY + 150; 

  pushMatrix();
  translate(offsetX, offsetY); 

  for (int i = 0; i < numSteps * 20; i++) { 
    drawStep(i * stepW, height - (i * stepH));
  }

  // --- 5. 人間の描画（疲労演出を再調整） ---
  drawBalancedFatiguePictogram(playerX, playerY, staminaRatio, p, fatigue);
  
  popMatrix();

  drawUI();
}

void drawStep(float x, float y) {
  noStroke();
  fill(0); 
  rect(x, y, stepW + 1, stepH + 800); 
}

void drawBalancedFatiguePictogram(float x, float y, float ratio, float p, float f) {
  pushMatrix();
  
  // --- パラメーター（1:2:5 比率） ---
  float s = 0.7; 
  float legL = stepH * 2.0;    
  float totalH = stepH * 5.0;  
  float torsoH = totalH - legL; 
  
  float legStretch = 0.4; 
  float bodyXOffset = stepW * 0.35; 
  float bodyYOffset = -legL; 

  // --- 疲労演出の調整エリア ---
  
  // 1. 肩の呼吸：少しゆっくり、幅も小さく (以前の12から6へ)
  float breath = sin(frameCount * 0.15) * 6 * f; 
  
  // 2. 体の沈み込み：重力感はしっかり出す
  float slump = 10 + (f * 35 * s); 
  
  // 3. 全体の揺れ：重心のふらつき
  float wobble = cos(frameCount * 0.08) * 8 * f * s;
  
  translate(x + bodyXOffset + wobble, y + bodyYOffset + slump);
  
  float lean = radians(5); 
  rotate(lean);

  float hipX = 0, hipY = 0; 
  float shoulderX = 0, shoulderY = -(torsoH - 50 * s) + breath; 
  
  // 胴体
  noStroke();
  fill(0);
  float torsoW = 40 * s;
  rect(-torsoW/2, shoulderY, torsoW, abs(shoulderY), 12 * s); 
  
  // 頭
  ellipse(0, shoulderY - 35 * s + (f * 6 * s), 45 * s, 45 * s);

  stroke(0);
  strokeWeight(24 * s);
  noFill();

  boolean isLeftStep = (floor(walkCycle) % 2 == 0);
  
  // --- 足の連続計算 ---
  float anchorX = lerp(0, -stepW * legStretch, p);
  float anchorY = lerp(legL, legL + stepH, p) - slump;
  float anchorKneeX = anchorX + 12 * s;
  float anchorKneeY = lerp(hipY, anchorY, 0.5) + 12 * s;

  // 足の上がりの低下：一段登るのが「しんどい」と感じる重要なポイント
  float normalLift = -80 * s;
  float lift = normalLift * (0.2 + 0.8 * ratio) * sin(p * PI); 
  
  float swingX = lerp(-stepW * legStretch, stepW * legStretch, p);
  float swingY = lerp(legL + stepH, legL - stepH, p) + lift - slump;
  
  // 4. 膝の震え：発生タイミングを遅くし、震え幅も小さく (以前の8から3へ)
  float shakeRange = 3 * f * f; 
  float shake = (ratio < 0.15) ? random(-shakeRange, shakeRange) : 0;
  
  float swingKneeX = swingX + 30 * s * ratio + shake;
  float swingKneeY = lerp(hipY, swingY, 0.5) - 20 * s + (lift * 0.4) + shake;

  if (isLeftStep) {
    drawLimb(hipX, hipY, swingKneeX, swingKneeY, swingX, swingY); 
    drawLimb(hipX, hipY, anchorKneeX, anchorKneeY, anchorX, anchorY); 
  } else {
    drawLimb(hipX, hipY, anchorKneeX, anchorKneeY, anchorX, anchorY); 
    drawLimb(hipX, hipY, swingKneeX, swingKneeY, swingX, swingY); 
  }

  // --- 腕の計算（振りも少し控えめに） ---
  float armSwingRange = 40 * s * (0.4 + 0.6 * ratio);
  float armSwing = sin(p * PI + (isLeftStep ? 0 : PI)) * armSwingRange;
  float elbowY = shoulderY + 55 * s; 
  float handY = shoulderY + 100 * s;
  
  drawLimb(shoulderX, shoulderY, shoulderX + 25 * s + armSwing, elbowY, shoulderX + 40 * s + armSwing, handY);
  drawLimb(shoulderX, shoulderY, shoulderX - 25 * s - armSwing, elbowY, shoulderX - 40 * s - armSwing, handY + 15 * s);
  
  popMatrix();
}

void drawLimb(float x1, float y1, float kx, float ky, float x2, float y2) {
  beginShape();
  vertex(x1, y1);
  vertex(kx, ky);
  vertex(x2, y2);
  endShape();
}

void drawUI() {
  textAlign(LEFT, CENTER);
  noStroke();
  fill(0, 150);
  rect(10, 10, 140, 35, 8); 
  fill(255);
  textSize(20);
  text("STEPS: " + stepCount, 25, 26);

  float gaugeW = 400; 
  float gaugeH = 25;  
  float gaugeX = (width - gaugeW) / 2;
  float gaugeY = 50;

  textAlign(CENTER, BOTTOM);
  fill(0);
  textSize(18);
  text("STAMINA", width / 2, gaugeY - 5);

  fill(220);
  rect(gaugeX, gaugeY, gaugeW, gaugeH, 12);

  color exhaustedColor = color(255, 50, 50); 
  color freshColor = color(50, 255, 100);  
  fill(lerpColor(exhaustedColor, freshColor, stamina/100.0));
  
  float currentBarW = map(stamina, 0, 100, 0, gaugeW);
  rect(gaugeX, gaugeY, currentBarW, gaugeH, 12);
  
  if (stamina < 10 && frameCount % 30 < 15) {
    fill(255, 0, 0);
    textSize(28);
    textAlign(CENTER, TOP);
    text("EXHAUSTED!", width / 2, gaugeY + 40);
  }
}
