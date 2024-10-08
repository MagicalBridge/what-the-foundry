const ASSETS = [
  "c/small-db1eae6f.svg",
  "c/secure-a66bbdfe.svg",
  "c/simple-258b6ed5.svg",
  "c/rotate-e8fb6784.wasm",
  "c/imagequant-a10bbe1a.wasm",
  "c/squoosh_oxipng_bg-5c8fadb7.wasm",
  "c/squoosh_oxipng_bg-60d7d0b0.wasm",
  "c/wp2_dec-9a40adf1.wasm",
  "c/qoi_enc-9285b08c.wasm",
  "c/webp_dec-12bed04a.wasm",
  "c/webp_enc_simd-75acd924.wasm",
  "c/webp_enc-a8223a7d.wasm",
  "c/qoi_dec-3728a8ee.wasm",
  "c/jxl_dec-e90a5afa.wasm",
  "c/mozjpeg_enc-f6bf569c.wasm",
  "c/wp2_enc-89317929.wasm",
  "c/wp2_enc_mt-1feb6658.wasm",
  "c/wp2_enc_mt_simd-0b0595e9.wasm",
  "c/avif_dec-d634d9c0.wasm",
  "c/jxl_enc_mt-669d03c7.wasm",
  "c/jxl_enc_mt_simd-efe18ebf.wasm",
  "c/jxl_enc-68f8271f.wasm",
  "c/avif_enc-2829b554.wasm",
  "c/avif_enc_mt-9d34100e.wasm",
  "c/squoosh_resize_bg-3d426466.wasm",
  "c/squooshhqx_bg-6e04a330.wasm",
  "c/initial-app-3a8274ec.js",
  "c/idb-keyval-1397a23c.js",
  "c/supports-wasm-threads-7bf00803.js",
  "c/features-worker-bfaa987d.js",
  "c/util-f21aefc7.js",
  "c/jxl_enc_mt_simd.worker-5c034784.js",
  "c/jxl_enc_mt.worker-59aad167.js",
  "c/avif_enc_mt.worker-a4e6d1c6.js",
  "c/wp2_enc_mt.worker-0c12e60a.js",
  "c/wp2_enc_mt_simd.worker-ae11823e.js",
  "c/workerHelpers-41103dbd.js",
  "c/Compress-debcf947.js",
  "c/sw-bridge-b7734752.js",
  "c/index.es-0cfdc30f.js",
  "c/blob-anim-2a2746fa.js",
  "c/avif_dec-9302012e.js",
  "c/webp_dec-489c2469.js",
  "c/avif_enc_mt-92518da4.js",
  "c/avif_enc-3bad6bea.js",
  "c/jxl_enc_mt_simd-444b7bc0.js",
  "c/jxl_enc_mt-c593b49e.js",
  "c/jxl_enc-414444ba.js",
  "c/squoosh_oxipng-039bce02.js",
  "c/squoosh_oxipng-c79339d1.js",
  "c/webp_enc_simd-67974fb0.js",
  "c/webp_enc-69f14351.js",
  "c/wp2_enc_mt_simd-ce60ffd3.js",
  "c/wp2_enc_mt-bde5d606.js",
  "c/wp2_enc-8dbc39db.js"
];
const VERSION = "e4dbd9782a6f6dbceb6429862dd3596ff5faafea";
if(!self.define){let e={};const A=(A,t)=>(A=A.startsWith(location.origin)?A:new URL(A+".js",t).href,e[A]||new Promise((e=>{if("document"in self){const t=document.createElement("link");t.rel="preload",t.as="script",t.href=A,t.onload=()=>{const t=document.createElement("script");t.src=A,t.onload=e,document.head.appendChild(t)},document.head.appendChild(t)}else self.nextDefineUri=A,importScripts(A),e()})).then((()=>{let t=e[A];if(!t)throw new Error(`Module ${A} didn’t register its module`);return t})));self.define=(t,n)=>{const a=self.nextDefineUri||("document"in self?document.currentScript.src:"")||location.href;if(e[a])return;let _={};const s=e=>A(e,a),i={module:{uri:a},exports:_,require:s};e[a]=Promise.resolve().then((()=>Promise.all(t.map((e=>i[e]||s(e)))))).then((e=>(n(...e),_)))}}define(["./c/supports-wasm-threads-7bf00803","./c/idb-keyval-1397a23c"],(function(e,A){var t="data:image/webp;base64,UklGRh4AAABXRUJQVlA4TBEAAAAvAAAAAAfQ//73v/+BiOh/AAA=",n="data:image/avif;base64,AAAAIGZ0eXBhdmlmAAAAAGF2aWZtaWYxbWlhZk1BMUEAAADybWV0YQAAAAAAAAAoaGRscgAAAAAAAAAAcGljdAAAAAAAAAAAAAAAAGxpYmF2aWYAAAAADnBpdG0AAAAAAAEAAAAeaWxvYwAAAABEAAABAAEAAAABAAABGgAAABUAAAAoaWluZgAAAAAAAQAAABppbmZlAgAAAAABAABhdjAxQ29sb3IAAAAAamlwcnAAAABLaXBjbwAAABRpc3BlAAAAAAAAAAEAAAABAAAAEHBpeGkAAAAAAwgICAAAAAxhdjFDgS0AAAAAABNjb2xybmNseAACAAIAAoAAAAAXaXBtYQAAAAAAAAABAAEEAQKDBAAAAB1tZGF0EgAKBDgADskyCx/wAABYAAAAAK+w";const a="/cdn/c/initial-app-3a8274ec.js",_=["/cdn/c/small-db1eae6f.svg","/cdn/c/simple-258b6ed5.svg","/cdn/c/secure-a66bbdfe.svg"],s="/cdn/c/Compress-debcf947.js",i=["/cdn/c/initial-app-3a8274ec.js","/cdn/c/util-f21aefc7.js","/cdn/c/features-worker-bfaa987d.js","/cdn/c/small-db1eae6f.svg","/cdn/c/simple-258b6ed5.svg","/cdn/c/secure-a66bbdfe.svg"],r="/cdn/c/sw-bridge-b7734752.js",c=["/cdn/c/idb-keyval-1397a23c.js","/cdn/serviceworker.js"],o="/cdn/c/blob-anim-2a2746fa.js",l=["/cdn/c/initial-app-3a8274ec.js","/cdn/c/small-db1eae6f.svg","/cdn/c/simple-258b6ed5.svg","/cdn/c/secure-a66bbdfe.svg"],N="/cdn/c/features-worker-bfaa987d.js",E=["/cdn/c/util-f21aefc7.js","/cdn/c/supports-wasm-threads-7bf00803.js","/cdn/c/jxl_dec-e90a5afa.wasm","/cdn/c/qoi_dec-3728a8ee.wasm","/cdn/c/wp2_dec-9a40adf1.wasm","/cdn/c/mozjpeg_enc-f6bf569c.wasm","/cdn/c/qoi_enc-9285b08c.wasm","/cdn/c/rotate-e8fb6784.wasm","/cdn/c/imagequant-a10bbe1a.wasm","/cdn/c/squoosh_resize_bg-3d426466.wasm","/cdn/c/squooshhqx_bg-6e04a330.wasm"];var d=Object.freeze({__proto__:null,main:N,deps:E});const f="/cdn/c/avif_dec-9302012e.js",u=["/cdn/c/avif_dec-d634d9c0.wasm"];var p=Object.freeze({__proto__:null,main:f,deps:u});const T="/cdn/c/webp_dec-489c2469.js",m=["/cdn/c/webp_dec-12bed04a.wasm"];var P=Object.freeze({__proto__:null,main:T,deps:m});const D="/cdn/c/avif_enc_mt-92518da4.js",I=["/cdn/c/avif_enc_mt-9d34100e.wasm","/cdn/c/avif_enc_mt.worker-a4e6d1c6.js"];var h=Object.freeze({__proto__:null,main:D,deps:I});const U="/cdn/c/avif_enc-3bad6bea.js",w=["/cdn/c/avif_enc-2829b554.wasm"];var G=Object.freeze({__proto__:null,main:U,deps:w});const R="/cdn/c/jxl_enc_mt_simd-444b7bc0.js",L=["/cdn/c/jxl_enc_mt_simd-efe18ebf.wasm","/cdn/c/jxl_enc_mt_simd.worker-5c034784.js"];var Y=Object.freeze({__proto__:null,main:R,deps:L});const M="/cdn/c/jxl_enc_mt-c593b49e.js",S=["/cdn/c/jxl_enc_mt-669d03c7.wasm","/cdn/c/jxl_enc_mt.worker-59aad167.js"];var g=Object.freeze({__proto__:null,main:M,deps:S});const v="/cdn/c/jxl_enc-414444ba.js",b=["/cdn/c/jxl_enc-68f8271f.wasm"];var B=Object.freeze({__proto__:null,main:v,deps:b});const j="/cdn/c/squoosh_oxipng-039bce02.js",y=["/cdn/c/workerHelpers-41103dbd.js","/cdn/c/squoosh_oxipng_bg-5c8fadb7.wasm"];var O=Object.freeze({__proto__:null,main:j,deps:y});const z="/cdn/c/squoosh_oxipng-c79339d1.js",W=["/cdn/c/squoosh_oxipng_bg-60d7d0b0.wasm"];var k=Object.freeze({__proto__:null,main:z,deps:W});const x="/cdn/c/webp_enc_simd-67974fb0.js",q=["/cdn/c/webp_enc_simd-75acd924.wasm"];var Q=Object.freeze({__proto__:null,main:x,deps:q});const C="/cdn/c/webp_enc-69f14351.js",Z=["/cdn/c/webp_enc-a8223a7d.wasm"];var X=Object.freeze({__proto__:null,main:C,deps:Z});const F="/cdn/c/wp2_enc_mt_simd-ce60ffd3.js",K=["/cdn/c/wp2_enc_mt_simd-0b0595e9.wasm","/cdn/c/wp2_enc_mt_simd.worker-ae11823e.js"];var V=Object.freeze({__proto__:null,main:F,deps:K});const H="/cdn/c/wp2_enc_mt-bde5d606.js",J=["/cdn/c/wp2_enc_mt-1feb6658.wasm","/cdn/c/wp2_enc_mt.worker-0c12e60a.js"];var $=Object.freeze({__proto__:null,main:H,deps:J});const ee="/cdn/c/wp2_enc-8dbc39db.js",Ae=["/cdn/c/wp2_enc-89317929.wasm"];var te=Object.freeze({__proto__:null,main:ee,deps:Ae});function ne(e){return e.startsWith("/c/demo-")}let ae=new Set([s,...i,r,...c,o,...l]);ae=function(e,A){const t=new Set(e);for(const e of A)t.delete(e);return t}(ae,new Set([a,..._.filter((e=>e.endsWith(".js")||ne(e))),N,A.swUrl]));const _e=["/",...ae],se=(async()=>{const[A,a,_,s]=await Promise.all([e.checkThreadsSupport(),e.simd(),...[t,n].map((async e=>{if(!self.createImageBitmap)return!1;const A=await fetch(e),t=await A.blob();return createImageBitmap(t).then((()=>!0),(()=>!1))}))]),i=[];function r(e){i.push(e.main,...e.deps)}return r(d),s||r(p),_||r(P),r(A?h:G),r(A&&a?Y:A?g:B),r(A?O:k),r(a?Q:X),r(A&&a?V:A?$:te),[...new Set(i)]})();function ie(e){const A=e.request.formData();e.respondWith(Response.redirect("/?share-target")),e.waitUntil(async function(){var t;await(t="share-ready",new Promise((e=>{oe.has(t)||oe.set(t,[]),oe.get(t).push(e)})));const n=await self.clients.get(e.resultingClientId),a=(await A).get("file");n.postMessage({file:a,action:"load-image"})}())}function re(e){return e.map((e=>new Request(e,{cache:"no-cache"})))}async function ce(e){return(await caches.open(e)).addAll(re(await se))}const oe=new Map;self.addEventListener("message",(e=>{const A=oe.get(e.data);if(A){oe.delete(e.data);for(const e of A)e()}}));const le="static-"+VERSION,Ne="dynamic",Ee=[le,Ne];self.addEventListener("install",(e=>{e.waitUntil(async function(){const e=[];e.push(async function(e){return(await caches.open(e)).addAll(re(_e))}(le)),await A.get("user-interacted")&&e.push(ce(le)),await Promise.all(e)}())})),self.addEventListener("activate",(e=>{self.clients.claim(),e.waitUntil(async function(){const e=(await caches.keys()).map((e=>{if(!Ee.includes(e))return caches.delete(e)}));await Promise.all(e)}())})),self.addEventListener("fetch",(e=>{const A=new URL(e.request.url);if(A.origin===location.origin)if("/editor"!==A.pathname){if("/"===A.pathname&&A.searchParams.has("share-target")&&"POST"===e.request.method)ie(e);else if("GET"===e.request.method)return ne(A.pathname)?(function(e,A){e.respondWith(async function(){const{request:t}=e,n=await caches.match(t);if(n)return n;const a=await fetch(t),_=a.clone();return e.waitUntil(async function(){const e=await caches.open(A);await e.put(t,_)}()),a}())}(e,Ne),void function(e,A,t){e.waitUntil(async function(){const e=await caches.open(A),n=(await e.keys()).map((A=>{const n=new URL(A.url).pathname.slice(1);if(!t.includes(n))return e.delete(A)}));await Promise.all(n)}())}(e,Ne,ASSETS)):void function(e){e.respondWith(async function(){return await caches.match(e.request,{ignoreSearch:!0})||fetch(e.request)}())}(e)}else e.respondWith(Response.redirect("/"))})),self.addEventListener("message",(e=>{switch(e.data){case"cache-all":e.waitUntil(ce(le));break;case"skip-waiting":self.skipWaiting()}}))}));
