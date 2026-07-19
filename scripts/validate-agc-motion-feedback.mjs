import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const profilePath = 'entry/src/main/ets/pages/ProfilePage.ets';
const index = fs.readFileSync(indexPath, 'utf8');
const profile = fs.readFileSync(profilePath, 'utf8');
const outfits = fs.readFileSync('entry/src/main/ets/pages/OutfitsPage.ets', 'utf8');
const wardrobe = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');
const storeVisit = fs.readFileSync('entry/src/main/ets/pages/StoreVisitPage.ets', 'utf8');

function methodSource(source, methodName) {
  const signature = new RegExp(`private (?:async )?${methodName}\\(`).exec(source);
  if (signature === null) {
    throw new Error(`Index missing route method ${methodName}`);
  }

  const bodyStart = source.indexOf('{', signature.index);
  let depth = 0;
  for (let index = bodyStart; index < source.length; index++) {
    if (source[index] === '{') depth++;
    if (source[index] === '}') depth--;
    if (depth === 0) return source.slice(signature.index, index + 1);
  }

  throw new Error(`Index route method ${methodName} has an incomplete body`);
}

function matchingBraceEnd(source, bodyStart) {
  let depth = 0;
  for (let index = bodyStart; index < source.length; index++) {
    if (source[index] === '{') depth++;
    if (source[index] === '}') depth--;
    if (depth === 0) return index;
  }
  return -1;
}

function assertAnimationHelper(source, file, helperName) {
  const helper = methodSource(source, helperName);
  const animatedChange = /this\.getUIContext\(\)\.animateTo\(\{\s*duration: 180,\s*curve: Curve\.EaseOut\s*\},\s*\(\) => \{\s*change\(\);\s*\}\);/;
  if (!animatedChange.test(helper)) {
    throw new Error(`${file} ${helperName} must run changes inside a 180ms UIContext animation`);
  }
}

function assertStateAssignmentsAnimated(source, file, stateNames, helperName) {
  const assignment = new RegExp(`this\\.(?:${stateNames.join('|')})\\s*=`, 'g');
  const helperCall = `this.${helperName}(() => {`;
  let count = 0;
  for (const match of source.matchAll(assignment)) {
    count++;
    const helperStart = source.lastIndexOf(helperCall, match.index);
    const bodyStart = helperStart < 0 ? -1 : source.indexOf('{', helperStart);
    const bodyEnd = bodyStart < 0 ? -1 : matchingBraceEnd(source, bodyStart);
    if (helperStart < 0 || match.index > bodyEnd) {
      throw new Error(`${file} structural state assignment must be inside ${helperName}: ${match[0]}`);
    }
  }
  if (count === 0) {
    throw new Error(`${file} has no structural state assignments to validate`);
  }
}

function assertComponentTransitions(source, file, componentNames, expectedCount) {
  const transition = '.transition(TransitionEffect.OPACITY)';
  const transitionCount = source.split(transition).length - 1;
  if (transitionCount !== expectedCount) {
    throw new Error(`${file} must keep ${expectedCount} nested root opacity transitions, found ${transitionCount}`);
  }

  for (const componentName of componentNames) {
    const componentStart = source.indexOf(`${componentName}({`);
    const branchEnd = source.indexOf('\n    } else', componentStart);
    if (componentStart < 0 || branchEnd < 0 || !source.slice(componentStart, branchEnd).includes(transition)) {
      throw new Error(`${file} ${componentName} root must keep an opacity transition`);
    }
  }
}

function builderSource(source, builderName) {
  const signature = source.indexOf(`\n  ${builderName}() {`);
  if (signature < 0) {
    throw new Error(`ProfilePage missing builder ${builderName}`);
  }
  const bodyStart = source.indexOf('{', signature);
  const bodyEnd = matchingBraceEnd(source, bodyStart);
  return source.slice(signature, bodyEnd + 1);
}

const profileRootScroll = /Scroll\(\) \{[\s\S]*?\.width\('100%'\)\s*\.height\('100%'\)\s*\.scrollBar\(BarState\.Off\)\s*\.edgeEffect\(EdgeEffect\.Spring, \{ alwaysEnabled: true \}\)/;
if (!profileRootScroll.test(profile)) {
  throw new Error('ProfilePage root Scroll must keep spring feedback enabled at both boundaries');
}

const topLevelPages = [
  'ClothingEditPage',
  'OutfitEditPage',
  'StoreVisitEditPage',
  'WishlistPage',
  'CaptureEditPage',
  'WardrobePage',
  'StoreVisitPage',
  'OutfitsPage',
  'ProfilePage'
];
const routeTransition = '.transition(TransitionEffect.OPACITY)';

for (let pageIndex = 0; pageIndex < topLevelPages.length; pageIndex++) {
  const page = topLevelPages[pageIndex];
  const branchStart = index.indexOf(`${page}({`);
  const branchEnd = pageIndex < topLevelPages.length - 1 ?
    index.indexOf(`${topLevelPages[pageIndex + 1]}({`, branchStart) :
    index.indexOf('if (this.quickActionErrorMessage.length > 0)', branchStart);

  if (branchStart < 0 || branchEnd < 0 || branchEnd <= branchStart) {
    throw new Error(`Index missing top-level route branch ${page}`);
  }

  if (!index.slice(branchStart, branchEnd).includes(routeTransition)) {
    throw new Error(`${page} must keep the lightweight route fade transition`);
  }
}

const transitionToRoute = methodSource(index, 'transitionToRoute');
const animatedRouteAssignment = /this\.getUIContext\(\)\.animateTo\(\{\s*duration: 180,\s*curve: Curve\.EaseOut\s*\},\s*\(\) => \{\s*this\.activeRoute = route;\s*this\.featureNestedContentVisible = false;\s*\}\);/;
if (!animatedRouteAssignment.test(transitionToRoute)) {
  throw new Error('Index activeRoute assignment must stay inside the UIContext animation closure');
}

for (const methodName of [
  'showMainRoute',
  'openWishlistPage',
  'openCaptureEditor',
  'openQuickStoreEditor',
  'openQuickClothingEditor',
  'openQuickOutfitEditor'
]) {
  if (!methodSource(index, methodName).includes('this.transitionToRoute(')) {
    throw new Error(`Index ${methodName} must enter the route animation context`);
  }
}

const returnToCaptureSource = methodSource(index, 'returnToCaptureSource');
if (!returnToCaptureSource.includes('this.activeRoute.kind === AppRouteKind.CaptureEditor') ||
  !returnToCaptureSource.includes('this.transitionToRoute(route);') ||
  !returnToCaptureSource.includes('this.setRouteWithoutTransition(route);')) {
  throw new Error('Capture editor must animate back while QuickCapture dismissal stays independent');
}

const openQuickActions = methodSource(index, 'openQuickActions');
if (!openQuickActions.includes('this.setRouteWithoutTransition(') || openQuickActions.includes('transitionToRoute')) {
  throw new Error('QuickCaptureSheet must not be wrapped in the route animation context');
}

const directRouteAssignments = index.match(/this\.activeRoute\s*=/g) ?? [];
if (directRouteAssignments.length !== 3) {
  throw new Error(`Structural route changes must use transitionToRoute, found ${directRouteAssignments.length} direct assignments`);
}

if (index.includes('TransitionEffect.OPACITY.animation(')) {
  throw new Error('Route transition timing must come from one UIContext animation context');
}

for (const [file, source, states] of [
  ['OutfitsPage', outfits, ['showOutfitDetail', 'showOutfitEditor', 'showWearLogEditor', 'showUnifiedSearch']],
  ['WardrobePage', wardrobe, ['showEditor', 'showClothingDetail', 'showUnifiedSearch']],
  ['StoreVisitPage', storeVisit, ['showEditor', 'showDetail']]
]) {
  assertAnimationHelper(source, file, 'animateNestedPageChange');
  assertStateAssignmentsAnimated(source, file, states, 'animateNestedPageChange');
  if (source.includes('TransitionEffect.OPACITY.animation(')) {
    throw new Error(`${file} nested transition timing must come from one UIContext animation context`);
  }
}

assertComponentTransitions(outfits, 'OutfitsPage',
  ['OutfitEditPage', 'WearLogEditPage', 'OutfitDetailPage', 'SearchResultsPage'], 5);
assertComponentTransitions(wardrobe, 'WardrobePage',
  ['ClothingEditPage', 'ClothingDetailPage', 'SearchResultsPage'], 4);
assertComponentTransitions(storeVisit, 'StoreVisitPage',
  ['StoreVisitEditPage', 'StoreVisitDetailPage'], 3);

assertAnimationHelper(profile, 'ProfilePage', 'animateSheetChange');
assertStateAssignmentsAnimated(profile, 'ProfilePage',
  ['isEditingMeasurements', 'isEditingDistricts', 'isEditingBudget'], 'animateSheetChange');

for (const builderName of ['MeasurementSheet', 'DistrictSheet', 'BudgetSheet']) {
  if (!builderSource(profile, builderName).includes('.transition(TransitionEffect.OPACITY)')) {
    throw new Error(`ProfilePage ${builderName} root must keep an opacity transition`);
  }
}

for (const needle of [
  '.backgroundColor(YibuqueColor.scrimLight)',
  '.hitTestBehavior(HitTestMode.Block)',
  '.transition(TransitionEffect.OPACITY)'
]) {
  if (!profile.includes(needle)) {
    throw new Error(`ProfilePage blocking scrim missing ${needle}`);
  }
}

const profileTransitionCount = profile.split('.transition(TransitionEffect.OPACITY)').length - 1;
if (profileTransitionCount !== 4) {
  throw new Error(`ProfilePage must keep one scrim and three sheet transitions, found ${profileTransitionCount}`);
}

console.log('PASS');
