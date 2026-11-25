import { createClient } from 'npm:@supabase/supabase-js@2.57.4';
const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type','Access-Control-Allow-Methods':'POST, OPTIONS'};
const reply=(status:number,message:string)=>Response.json({message},{status,headers:cors});
Deno.serve(async(req)=>{
  if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
  if(req.method!=='POST')return reply(405,'Method not allowed');
  const url=Deno.env.get('SUPABASE_URL')!;
  const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const anonKey=Deno.env.get('SUPABASE_ANON_KEY')!;
  const token=req.headers.get('Authorization')?.replace(/^Bearer\s+/i,'');
  if(!token)return reply(401,'Sign in first');
  const admin=createClient(url,serviceKey,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:identity,error}=await admin.auth.getUser(token);
  if(error||!identity.user?.email)return reply(401,'Sign in first');
  // Proof that it's really the parent: a one-time code emailed to the
  // account (Curio's default), or the password for accounts that have one.
  let body:{code?:unknown;password?:unknown};
  try { const raw=await req.text();if(raw.length>2048)return reply(413,'Request too large');body=JSON.parse(raw); }catch{return reply(400,'Invalid request');}
  const {code,password}=body??{};
  // Both checks use the public auth endpoints, including their rate limits.
  const verifier=createClient(url,anonKey,{auth:{persistSession:false,autoRefreshToken:false}});
  let verifiedId:string|undefined;
  if(typeof code==='string'&&/^\d{6,10}$/.test(code)){
    const {data,error:codeError}=await verifier.auth.verifyOtp({email:identity.user.email,token:code,type:'email'});
    if(codeError)return reply(codeError.status===429?429:403,'Could not verify account');
    verifiedId=data.user?.id;
  }else if(typeof password==='string'&&password.length>=1&&password.length<=1024){
    const {data,error:passwordError}=await verifier.auth.signInWithPassword({email:identity.user.email,password});
    if(passwordError)return reply(passwordError.status===429?429:403,'Could not verify account');
    verifiedId=data.user?.id;
  }else{
    return reply(400,'Code or password required');
  }
  if(verifiedId!==identity.user.id)return reply(403,'Could not verify account');
  const {error:deleteError}=await admin.auth.admin.deleteUser(identity.user.id);
  if(deleteError)return reply(500,'Could not delete account');
  return reply(200,'Account deleted');
});
