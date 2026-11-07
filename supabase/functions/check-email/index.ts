import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.53.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    })
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({
        error: 'Method not allowed',
      }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(
      JSON.stringify({
        error: 'Missing Supabase environment variables',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  let payload: { email?: unknown }

  try {
    payload = (await req.json()) as { email?: unknown }
  } catch {
    return new Response(
      JSON.stringify({
        error: 'Invalid JSON body',
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const rawEmail = payload.email
  const email = typeof rawEmail === 'string' ? rawEmail.trim().toLowerCase() : ''

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@.]+$/.test(email)) {
    return new Response(
      JSON.stringify({
        error: 'Valid email is required',
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  })

  const {
    data: usersData,
    error: usersError,
  } = await supabase.auth.admin.listUsers()

  if (usersError) {
    return new Response(
      JSON.stringify({
        error: 'Unable to verify email availability',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const matchingUser = usersData?.users.find((user) => {
    return (user.email ?? '').trim().toLowerCase() === email
  })

  if (!matchingUser) {
    return new Response(
      JSON.stringify({
        exists: false,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', matchingUser.id)
    .maybeSingle()

  if (profileError && profileError.code !== 'PGRST116') {
    return new Response(
      JSON.stringify({
        error: 'Unable to verify email availability',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    )
  }

  const accountType =
    typeof profile?.role === 'string' ? profile.role.trim().toLowerCase() : null

  let technicianStatus: string | null = null

  if (accountType === 'technician') {
    const { data: technicianProfile, error: technicianError } = await supabase
      .from('technician_profiles')
      .select('status')
      .eq('profile_id', matchingUser.id)
      .maybeSingle()

    if (technicianError && technicianError.code !== 'PGRST116') {
      return new Response(
        JSON.stringify({
          error: 'Unable to verify email availability',
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      )
    }

    technicianStatus =
      typeof technicianProfile?.status === 'string'
        ? technicianProfile.status.trim().toLowerCase()
        : null
  }

  return new Response(
    JSON.stringify({
      exists: true,
      accountType,
      technicianStatus,
    }),
    {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    },
  )
})
