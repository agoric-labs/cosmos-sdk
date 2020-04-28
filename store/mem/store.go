package mem

import (
	"io"

	dbm "github.com/tendermint/tm-db"

	"github.com/cosmos/cosmos-sdk/store/dbadapter"
	"github.com/cosmos/cosmos-sdk/store/types"
)

var (
	_ types.KVStore   = (*Store)(nil)
	_ types.Committer = (*Store)(nil)
	_ types.Store     = (*Store)(nil)
)

// Store implements an in-memory only KVStore. Entries are persisted between
// commits and thus between blocks. State in Memory store is not committed as part of app state but maintained privately by each node
type Store struct {
	dbadapter.Store
}

func NewStore() *Store {
	return NewStoreWithDB(dbm.NewMemDB())
}

func NewStoreWithDB(db *dbm.MemDB) *Store { // nolint: interfacer
	return &Store{Store: dbadapter.Store{DB: db}}
}

// GetStoreType returns the Store's type.
func (s *Store) GetStoreType() types.StoreType {
	return types.StoreTypeMemory
}

// CacheWrap cache wraps the underlying store.
func (s *Store) CacheWrap() types.CacheWrap {
	// FIXME: Caching doesn't work.
	return s
	// With the following enabled, changes are not always written to the Store
	// return cachekv.NewStore(s)
}

// CacheWrapWithTrace implements KVStore.
func (s *Store) CacheWrapWithTrace(w io.Writer, tc types.TraceContext) types.CacheWrap {
	// FIXME: Caching doesn't work.
	return s
	// With the following enabled, changes are not always written to the Store
	// return cachekv.NewStore(tracekv.NewStore(s, w, tc))
}

func (s *Store) Write() {}

// Commit performs a no-op as entries are persistent between commitments.
func (s *Store) Commit() (id types.CommitID) { return }

/*
	fmt.Printf("FIGME: Got commit for %p %#v\n", s, *s)
	it, err := s.DB.Iterator(nil, nil)
	if err != nil {
		fmt.Println("FIGME: Cannot iterate", err)
		return
	}
	for it.Valid() {
		fmt.Printf("FIGME:   %s = ", string(it.Key()))
		val := it.Value()
		if val[0] == 0 {
			fmt.Println(val)
		} else {
			fmt.Println(string(val))
		}
		it.Next()
	}
	fmt.Println("FIGME: DONE commit")
*/

// nolint
func (s *Store) SetPruning(pruning types.PruningOptions) {}
func (s *Store) LastCommitID() (id types.CommitID)       { return }
